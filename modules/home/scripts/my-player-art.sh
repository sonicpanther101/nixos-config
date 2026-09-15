#!/usr/bin/env bash
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player"

PLAYER=$(cat "$STATE_FILE" 2>/dev/null)
[ -z "$PLAYER" ] && exit 0

# 1. Try to fetch the media artwork (Browsers automatically set this to tab artwork/favicons when playing media)
ART=$(playerctl -p "$PLAYER" metadata mpris:artUrl 2>/dev/null | sed 's|^file://||')

if [ -n "$ART" ]; then
    echo "$ART"
    exit 0
fi

# 2. Fallback: Identify the application desktop entry name
APP_NAME=$(playerctl -p "$PLAYER" metadata xdg:desktopEntry 2>/dev/null)
[ -z "$APP_NAME" ] && APP_NAME=$(echo "$PLAYER" | cut -d'.' -f1 | tr '[:upper:]' '[:lower:]')

# 3. Search standard system icon directories for the application icon (.png or .svg)
ICON_PATH=$(find /usr/share/icons ~/.local/share/icons /usr/share/pixmaps \
    -type f \( -name "${APP_NAME}.png" -o -name "${APP_NAME}.svg" \) 2>/dev/null | head -n 1)

echo "$ICON_PATH"
