#!/usr/bin/env bash
set -u
shopt -s nullglob

IPOD="/run/media/adam/ADAM_S IPOD"
SRC="$HOME/driveBig/IPod"
DEST="$IPOD/iPod_Control/Music/F00"
RESERVE=$((100 * 1024 * 1024))   # spare room kept free for the DB rebuild
TOTAL_STAGES=4
FILTER='s%[/\\?*:|"<>]+%-%g; s/\s+-\s+-/ -/g; s/^\s+|\s+$//g'

# ---------- progress helpers ----------
# progress "label" current total
progress() {
    local label=$1 cur=$2 total=$3 width=30
    local pct=100
    (( total > 0 )) && pct=$(( cur * 100 / total ))
    (( pct > 100 )) && pct=100
    local filled=$(( pct * width / 100 ))
    local bar rest
    bar=$(printf '%*s' "$filled" '' | tr ' ' '#')
    rest=$(printf '%*s' "$(( width - filled ))" '' | tr ' ' '-')
    printf '\r\033[K%s [%s%s] %3d%%' "$label" "$bar" "$rest" "$pct"
}

stage() { printf '\n\033[1m[%d/%d] %s\033[0m\n' "$1" "$TOTAL_STAGES" "$2"; }
human() { numfmt --to=iec --suffix=B "$1" 2>/dev/null || echo "$1 B"; }

Update() {
    cd "$IPOD" || { echo "iPod not mounted"; exit 1; }
    stage 4 "Rebuilding iPod database"
    python3 ./3build_db.py || exit 1
    echo "Syncing to disk (this can take a while)..."
    sync
    echo "Done."
}

while getopts "u" option; do
    case $option in
        u)
            Update
            exit;;
        \?)
            echo "Error: Invalid option"
            exit 1;;
    esac
done

cd "$SRC" || { echo "Can't cd to $SRC"; exit 1; }

# ---------- 1. Convert FLAC to MP3 ----------
stage 1 "Converting FLAC to MP3"
flacs=(*.flac)
if (( ${#flacs[@]} )); then
    declare -a durs
    total_us=0
    for i in "${!flacs[@]}"; do
        durs[i]=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "${flacs[i]}" \
                  | awk '{printf "%d", $1 * 1000000}')
        total_us=$(( total_us + ${durs[i]:-0} ))
    done

    done_us=0
    for i in "${!flacs[@]}"; do
        f=${flacs[i]}
        n=$(( i + 1 ))
        label="  $n/${#flacs[@]}"
        ffmpeg -nostdin -y -loglevel error -progress pipe:1 -nostats \
            -i "$f" -map_metadata 0 -c:v copy \
            -codec:a libmp3lame -qscale:a 2 "${f%.flac}.mp3" \
        | while IFS='=' read -r k v; do
            if [[ $k == out_time_us && $v =~ ^[0-9]+$ ]]; then
                progress "$label" $(( done_us + v )) "$total_us"
            fi
          done
        if (( PIPESTATUS[0] == 0 )); then
            rm -- "$f"
        else
            printf '\n  ffmpeg failed on %s (keeping the FLAC)\n' "$f"
        fi
        done_us=$(( done_us + ${durs[i]:-0} ))
        progress "$label" "$done_us" "$total_us"
    done
    echo
else
    echo "  No FLAC files to convert."
fi

# ---------- 2. Rename MP3s according to ID3 metadata ----------
stage 2 "Renaming MP3s from tags"
new=(*.mp3)
if (( ${#new[@]} )); then
    exiftool -q -api "Filter=$FILTER" \
        '-filename<${Band} - (${RecordingTime}) ${Album} - ${Track} ${Title}.%e' \
        "${new[@]}"
    echo "  Done."
else
    echo "  No MP3 files to rename."
fi

# ---------- 3. Copy album by album ----------
stage 3 "Copying albums to iPod"
mountpoint -q "$IPOD" || { echo "iPod not mounted"; exit 1; }
mkdir -p "$DEST"
rm -f -- "$DEST"/*          # permanent delete, no trash

mp3s=(*.mp3)
(( ${#mp3s[@]} )) || { echo "  No MP3 files to copy."; Update; exit; }

# Group the flat files into albums using the tags (same key as the filename prefix).
# Two exiftool passes keep the real filenames unfiltered; both list files in the same order.
keys=(); files=()
prev=""; idx=-1
while IFS=$'\t' read -r key file; do
    if (( idx < 0 )) || [[ $key != "$prev" ]]; then
        idx=$(( idx + 1 )); keys[idx]=$key; files[idx]=""; prev=$key
    fi
    files[idx]+="$file"$'\n'
done < <(paste \
            <(exiftool -q -f -api "Filter=$FILTER" -p '${Band} - (${RecordingTime}) ${Album}' "${mp3s[@]}") \
            <(exiftool -q -f -p '${FileName}' "${mp3s[@]}") \
         | LC_ALL=C sort -s -t $'\t' -k1,1)

free=$(df --output=avail -B1 "$IPOD" | tail -n1)
free=$(( free - RESERVE ))
bs=$(stat -f -c %S "$IPOD")  # target cluster size

# Plan: decide which albums fit before copying anything
plan=()          # indexes into keys/files
total_bytes=0
for idx in "${!keys[@]}"; do
    mapfile -t tracks <<< "${files[idx]%$'\n'}"

    # size on the iPod (each file rounded up to a whole cluster), and raw size
    read -r size raw < <(printf '%s\0' "${tracks[@]}" | xargs -0 stat -c %s -- \
        | awk -v bs="$bs" '{c += int(($1 + bs - 1) / bs) * bs; r += $1} END {print c + 0, r + 0}')

    if (( size > free )); then
        echo "  Not enough room for '${keys[idx]}' ($(human "$size") needed, $(human "$free") free). Stopping here."
        break
    fi
    free=$(( free - size ))
    plan+=("$idx")
    total_bytes=$(( total_bytes + raw ))
done

echo "  ${#plan[@]} album(s) to copy, $(human "$total_bytes") total."

copied=0
n=0
for idx in "${plan[@]}"; do
    n=$(( n + 1 ))
    label="  Album $n/${#plan[@]}"
    mapfile -t tracks <<< "${files[idx]%$'\n'}"
    failed=0
    for t in "${tracks[@]}"; do
        progress "$label" "$copied" "$total_bytes"
        if cp -- "$t" "$DEST"/; then
            copied=$(( copied + $(stat -c %s -- "$t") ))
        else
            failed=1
            break
        fi
    done
    if (( failed )); then
        printf '\n  Copy failed in "%s", removing partial album\n' "${keys[idx]}"
        for t in "${tracks[@]}"; do rm -f -- "$DEST/$t"; done
        break
    fi
    progress "$label" "$copied" "$total_bytes"
done
echo

# ---------- 4. Update iPod database ----------
Update
