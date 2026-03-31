DIR="$1"  # l or r
 
before_x=$(hyprctl activewindow -j | jq -r '.at[0]')
 
hyprctl dispatch movefocus "$DIR" > /dev/null 2>&1
 
after_x=$(hyprctl activewindow -j | jq -r '.at[0]')
 
case "$DIR" in
    l)
        [ "$after_x" -ge "$before_x" ] && 
            active_workspace=$(hyprctl monitors -j | jq -r '.[] | select(.id == '1') | .activeWorkspace.id')
            addr=$(hyprctl clients -j | jq -r '[.[] | select(.monitor == '1' and .workspace.id == '$active_workspace')] | max_by(.at[0]) | .address')
            hyprctl dispatch focuswindow "address:$addr"
        ;;
    r)
        [ "$after_x" -le "$before_x" ] && 
            active_workspace=$(hyprctl monitors -j | jq -r '.[] | select(.id == '0') | .activeWorkspace.id')
            addr=$(hyprctl clients -j | jq -r '[.[] | select(.monitor == '0' and .workspace.id == '$active_workspace')] | min_by(.at[0]) | .address')
            hyprctl dispatch focuswindow "address:$addr"
        ;;
esac