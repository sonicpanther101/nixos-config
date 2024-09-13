ags -q
hyprctl dispatch exec "[workspace 9 silent] kitty --hold sh -c 'ags'"
if playerctl status | grep "Playing"; then
    sleep 3
    playerctl pause
    sleep 0.1
    playerctl play
fi