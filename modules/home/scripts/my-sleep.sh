host=$(hostname)                        

if [[ $host == "desktop" ]]; then       
    openrgb --mode direct --color 000000 # Turn all RGB off, without opening openrgb
fi                                      

playerctl -p $(cat "${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player") pause   # Pause all media

# `;` not `&&`: if hypridle isn't running, pkill exits 1 and `&&` would skip the suspend entirely
pkill hypridle; systemctl suspend        # Put to sleep

hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'   # Turn display on first
sleep 0.5                                # Give compositor a moment
systemctl --user start hyprlock.service  # Start hyprlock in background
sleep 0.3
hyprctl dispatch 'hl.dsp.focus({ window = "class:hyprlock" })'  # Force focus

if [[ $host == "desktop" ]]; then       
    openrgb --mode direct --color 000000 # Turn all RGB off if started on boot
fi                  

cd ~/nixos-config && git fetch
