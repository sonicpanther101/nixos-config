DIR="$1"  # l, r, u, d
 
before=$(hyprctl activewindow -j | jq -r '.address')
 
hyprctl dispatch movefocus "$DIR" > /dev/null 2>&1
 
after=$(hyprctl activewindow -j | jq -r '.address')
 
# If the focused window didn't change, we're at the edge — cross the monitor
if [ "$before" = "$after" ]; then
    current_monitor=$(hyprctl activewindow -j | jq -r '.monitor')
    case "$DIR" in
        l)
            if [ "$current_monitor" = "0" ]; then
                hyprctl dispatch focusmonitor 1
            fi
            ;;
        r)
            if [ "$current_monitor" = "1" ]; then
                hyprctl dispatch focusmonitor 0
            fi
            ;;
    esac
fi