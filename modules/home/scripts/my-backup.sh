# Waybar custom module: backs up "Uni Notes" from a Ventoy USB when it's
# plugged in, and always prints a single-line JSON status waybar can read,
# whether or not the USB is present this run.
#
# Waybar module config should use: "return-type": "json"
#
set -uo pipefail  # no -e: we want to control exit/output paths ourselves

USB_SOURCE="/run/media/adam/Ventoy/Uni Notes"
BACKUP_ROOT="$HOME/Desktop/Uni-Notes-Backups"
STATE_FILE="$HOME/.cache/uni-notes-backup-state"
TODAY=$(date '+%Y-%m-%d')
TIMESTAMP=$(date '+%Y-%m-%d_%H')          # resolution: to the hour
DISPLAY_TIME=$(date '+%a %d %b, %l:%M %p' | sed 's/  / /')
NEW_BACKUP="$BACKUP_ROOT/Uni-Notes-$TIMESTAMP"
TMP_BACKUP="/tmp/uni-notes-backup-$$"

mkdir -p "$(dirname "$STATE_FILE")"

# --- state helpers -----------------------------------------------------
LAST_OK_TIME=""
LAST_ERROR=""

load_state() {
    [ -f "$STATE_FILE" ] && source "$STATE_FILE" 2>/dev/null || true
}

save_state() {
    printf 'LAST_OK_TIME=%q\nLAST_ERROR=%q\n' "$LAST_OK_TIME" "$LAST_ERROR" > "$STATE_FILE"
}

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/ | }"
    printf '%s' "$s"
}

emit() {
    # emit <text> <tooltip> <class>
    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
        "$(json_escape "$1")" "$(json_escape "$2")" "$3"
}

load_state

# --- no USB present: just report last known state ----------------------
if ! lsblk | grep -q Ventoy 2>/dev/null; then
    if [ -n "$LAST_ERROR" ]; then
        emit "⚠ backup error" "Last good backup: ${LAST_OK_TIME:-never}. Error: $LAST_ERROR" "error"
    elif [ -n "$LAST_OK_TIME" ]; then
        emit "$LAST_OK_TIME" "Last successful backup: $LAST_OK_TIME" "ok"
    else
        emit "no backup yet" "USB not connected, no backup on record" "idle"
    fi
    exit 0
fi

# --- USB present: attempt backup ---------------------------------------
mkdir -p "$BACKUP_ROOT"

if ! cp -r "$USB_SOURCE" "$TMP_BACKUP" 2>/tmp/uni-notes-backup-err; then
    LAST_ERROR="copy from USB failed"
    save_state
    rm -rf "$TMP_BACKUP"
    emit "⚠ copy failed" "Last good backup: ${LAST_OK_TIME:-never}. Copy from USB failed." "error"
    exit 1
fi

# xopp files are zip archives internally; flag any that fail an integrity
# test rather than let a corrupt file overwrite a good backup.
# unrar only understands .rar, not zip, so use p7zip for this check.
SEVENZ_BIN=""
for candidate in 7z 7za 7zr; do
    if command -v "$candidate" >/dev/null 2>&1; then
        SEVENZ_BIN="$candidate"
        break
    fi
done

bad_files=0
bad_list=""
if [ -z "$SEVENZ_BIN" ]; then
    LAST_ERROR="p7zip not found, cannot verify xopp integrity"
    save_state
    rm -rf "$TMP_BACKUP"
    emit "⚠ p7zip missing" "Install p7zip (7z) so backups can be integrity-checked." "error"
    exit 1
fi

while IFS= read -r -d '' f; do
    if ! "$SEVENZ_BIN" t "$f" >/dev/null 2>&1; then
        bad_files=$((bad_files + 1))
        bad_list="$bad_list $(basename "$f")"
    fi
done < <(find "$TMP_BACKUP" -name '*.xopp' -print0)

if [ "$bad_files" -gt 0 ]; then
    LAST_ERROR="$bad_files corrupt xopp file(s):$bad_list"
    save_state
    rm -rf "$TMP_BACKUP"
    emit "⚠ $bad_files corrupt file(s)" "Last good backup: ${LAST_OK_TIME:-never}. Corrupt:$bad_list" "error"
    exit 1
fi

# Good copy: drop any earlier backup(s) from today, promote this one.
find "$BACKUP_ROOT" -maxdepth 1 -type d -name "Uni-Notes-${TODAY}_*" -exec rm -rf {} +
mv "$TMP_BACKUP" "$NEW_BACKUP"

# Retention: drop daily backups older than 2 weeks.
find "$BACKUP_ROOT" -maxdepth 1 -type d -name "Uni-Notes-*" -mtime +14 -exec rm -rf {} +

LAST_OK_TIME="$DISPLAY_TIME"
LAST_ERROR=""
save_state

emit "$DISPLAY_TIME" "Backed up (verified with $SEVENZ_BIN): $DISPLAY_TIME -> $NEW_BACKUP" "ok"
