host=$(hostname)                        

if [[ $host == "desktop" ]]; then       
    openrgb --mode direct --color 000000 # Turn all RGB off, without opening openrgb
fi                                      

playerctl -p $(cat "${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player") pause   # Pause current media

pkill hypridle && systemctl suspend      # Put to sleep

hyprctl dispatch "hl.dsp.dpms({ action = \"on\" })"                 # Turn display on first
sleep 0.5                                # Give compositor a moment
systemctl --user start hyprlock.service  # Start hyprlock in background

if [[ $host == "desktop" ]]; then       
    openrgb --mode direct --color 000000 # Turn all RGB off if started on boot
fi                  

cd ~/nixos-config && git fetch
