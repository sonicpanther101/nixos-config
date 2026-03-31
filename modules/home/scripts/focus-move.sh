DIR="$1"  # l or r
 
before_x=$(hyprctl activewindow -j | jq -r '.at[0]')
 
hyprctl dispatch movefocus "$DIR" > /dev/null 2>&1
 
after=$(hyprctl activewindow -j)
after_x=$(echo "$after" | jq -r '.at[0]')
 
case "$DIR" in
    l) [ "$after_x" -ge "$before_x" ] && hyprctl dispatch focusmonitor 1 ;;
    r) [ "$after_x" -le "$before_x" ] && hyprctl dispatch focusmonitor 0 ;;
esac