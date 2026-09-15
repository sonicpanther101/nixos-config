#!/usr/bin/env bash
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player"

PLAYER=$(cat "$STATE_FILE" 2>/dev/null)
[ -z "$PLAYER" ] && exit 0

# 1. Fast path: Return album/tab art immediately if available
ART=$(playerctl -p "$PLAYER" metadata mpris:artUrl 2>/dev/null | sed 's|^file://||')
if [ -n "$ART" ]; then
    echo "$ART"
    exit 0
fi

# 2. Extract base application name
APP_NAME=$(playerctl -p "$PLAYER" metadata xdg:desktopEntry 2>/dev/null)
[ -z "$APP_NAME" ] && APP_NAME=$(echo "$PLAYER" | cut -d'.' -f1 | tr '[:upper:]' '[:lower:]')

# 3. Cache lookup: Return instantly if cached and valid (~2ms)
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-app-icons"
CACHE_FILE="$CACHE_DIR/$APP_NAME"
if [ -f "$CACHE_FILE" ]; then
    CACHED_PATH=$(cat "$CACHE_FILE")
    if [ -f "$CACHED_PATH" ]; then
        echo "$CACHED_PATH"
        exit 0
    fi
fi

# 4. Filter active system search directories
IFS=':' read -ra XDG_ARR <<< "${XDG_DATA_DIRS:-/usr/share:~/.local/share}"
SEARCH_DIRS=(
    "${XDG_ARR[@]}"
    "$HOME/.local/share"
    "/run/current-system/sw/share"
    "$HOME/.nix-profile/share"
    "/etc/profiles/per-user/${USER:-adam}/share"
)

APP_DIRS=()
ICON_DIRS=()
for dir in "${SEARCH_DIRS[@]}"; do
    [ -d "$dir/applications" ] && APP_DIRS+=("$dir/applications")
    [ -d "$dir/icons" ] && ICON_DIRS+=("$dir/icons")
    [ -d "$dir/pixmaps" ] && ICON_DIRS+=("$dir/pixmaps")
done

# 5. Fast desktop file lookup
DESKTOP_FILE=""
shopt -s nullglob
for d in "${APP_DIRS[@]}"; do
    for f in "$d/"*"$APP_NAME"*.desktop; do
        if [ -f "$f" ]; then
            DESKTOP_FILE="$f"
            break 2
        fi
    done
done

ICON_NAME=""
if [ -n "$DESKTOP_FILE" ]; then
    ICON_NAME=$(grep -m 1 "^Icon=" "$DESKTOP_FILE" | cut -d'=' -f2)
fi

# Direct /nix/store absolute icon check
if [[ "$ICON_NAME" == /* ]] && [ -f "$ICON_NAME" ]; then
    mkdir -p "$CACHE_DIR" 2>/dev/null
    echo "$ICON_NAME" > "$CACHE_FILE"
    echo "$ICON_NAME"
    exit 0
fi

[ -z "$ICON_NAME" ] && ICON_NAME="$APP_NAME"

# 6. Targeted Icon lookup: Validate that matched file exists and is not a broken symlink
ICON_PATH=""
for name in "$ICON_NAME" "$APP_NAME"; do
    for icon_dir in "${ICON_DIRS[@]}"; do
        matches=(
            "$icon_dir"/*/*/apps/"$name".{svg,png}
            "$icon_dir"/*/apps/"$name".{svg,png}
            "$icon_dir"/apps/"$name".{svg,png}
            "$icon_dir"/"$name".{svg,png}
            "$icon_dir"/*/*/apps/*"$name"*.{svg,png}
            "$icon_dir"/*/apps/*"$name"*.{svg,png}
        )
        for match in "${matches[@]}"; do
            if [ -f "$match" ]; then
                ICON_PATH="$match"
                break 3
            fi
        done
    done
done
shopt -u nullglob

# 7. Write to cache & output result
if [ -n "$ICON_PATH" ]; then
    mkdir -p "$CACHE_DIR" 2>/dev/null
    echo "$ICON_PATH" > "$CACHE_FILE"
    echo "$ICON_PATH"
fi
