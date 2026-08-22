#!/usr/bin/env bash
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player"

PLAYER=$(cat "$STATE_FILE" 2>/dev/null)
[ -z "$PLAYER" ] && exit 0

playerctl -p "$PLAYER" metadata mpris:artUrl 2>/dev/null | sed 's|^file://||'
