MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')

if [ -z "$MONITOR" ]; then
  notify-send "Invert monitor" "Could not determine the focused monitor"
  exit 1
fi

if pgrep -f "wl-monitor-invert $MONITOR" > /dev/null; then
  pkill -f "wl-monitor-invert $MONITOR"
  notify-send "Invert monitor" "$MONITOR restored to normal"
else
  wl-monitor-invert "$MONITOR" &
  disown
  notify-send "Invert monitor" "$MONITOR inverted"
fi
