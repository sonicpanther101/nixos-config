ags -q
hyprctl dispatch exec "[workspace 9 silent] kitty --hold sh -c 'ags -c ~/nixos-config/modules/home/ags/ags/config.js'"
if playerctl status | grep "Playing"; then
    sleep 5
    playerctl pause
    sleep 0.1
    playerctl play
fi