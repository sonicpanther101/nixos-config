hyprctl dispatch exec "[workspace 9 silent] kitty --hold sh -c 'tachidesk-server'"
vivaldi --profile-directory="Profile 2"
sleep 5
xdg-open http://0.0.0.0:4567