host=$(hostname)                        

if [[ $host == "desktop" ]]; then       
    openrgb --mode direct --color 000000 # Turn all RGB off, without opening openrgb
fi                                      

playerctl pause                          # Pause all media

pkill hypridle && systemctl suspend      # Put to sleep

hyprctl dispatch dpms on                 # Turn display on first
sleep 0.5                                # Give compositor a moment
pidof hyprlock || hyprlock &             # Start hyprlock in background
sleep 0.3
hyprctl dispatch focuswindow class:hyprlock  # Force focus

if [[ $host == "desktop" ]]; then       
    openrgb --mode direct --color 000000 # Turn all RGB off if started on boot
fi                  

cd ~/nixos-config && git fetch