#!/usr/bin/env bash
# focus-move.sh <direction>
# Moves focus in the given direction. Crosses to the neighbouring monitor
# when hyprland would otherwise loop within the same monitor.

DIR="$1"  # l or r

before_monitor=$(hyprctl activewindow -j | jq -r '.monitor')

hyprctl dispatch movefocus "$DIR" > /dev/null 2>&1

after_monitor=$(hyprctl activewindow -j | jq -r '.monitor')

# If still on the same monitor, hyprland may have looped to the opposite edge.
# Check if the newly focused window is on the far side (indicating a wrap).
if [ "$before_monitor" = "$after_monitor" ]; then
    WIN=$(hyprctl activewindow -j)
    WIN_X=$(echo "$WIN" | jq -r '.at[0]')
    WIN_W=$(echo "$WIN" | jq -r '.size[0]')
    WIN_RIGHT=$((WIN_X + WIN_W))

    MONITOR=$(hyprctl monitors -j | jq ".[] | select(.id == $after_monitor)")
    MON_X=$(echo "$MONITOR" | jq -r '.x')
    MON_W=$(echo "$MONITOR" | jq -r '.width')
    MON_RIGHT=$((MON_X + MON_W))

    case "$DIR" in
        l)
            # Moved left but ended up at the right edge = wrap occurred
            if [ "$WIN_RIGHT" -ge "$((MON_RIGHT - 20))" ] && [ "$after_monitor" = "0" ]; then
                hyprctl dispatch focusmonitor 1
            fi
            ;;
        r)
            # Moved right but ended up at the left edge = wrap occurred
            if [ "$WIN_X" -le "$((MON_X + 20))" ] && [ "$after_monitor" = "1" ]; then
                hyprctl dispatch focusmonitor 0
            fi
            ;;
    esac
fi