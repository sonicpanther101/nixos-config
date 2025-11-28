host=$(hostname)                        

if [[ $host == "desktop" ]]; then       
    openrgb --mode direct --color 000000 # Turn all RGB off, without opening openrgb
fi                                      
playerctl pause                          # Pause all media
systemctl suspend                        # Put to sleep
pidof hyprlock || hyprlock               # Display lockscreen on wakeup

if [[ $host == "desktop" ]]; then       
    openrgb --mode direct --color 000000 # Turn all RGB off if started on boot
fi                                      
