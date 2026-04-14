host=$(hostname)                        

if [[ $host == "desktop" ]]; then       
    openrgb --mode direct --color 000000 # Turn all RGB off, without opening openrgb
fi                                      
playerctl pause                          # Pause all media
systemctl suspend                        # Put to sleep
pidof swaylock || swaylock               # Display lockscreen on wakeup

if [[ $host == "desktop" ]]; then       
    openrgb --mode direct --color 000000 # Turn all RGB off if started on boot
else
    pidof wvkbd-mobintl || wvkbd-mobintl & # Start OSK on non-desktop hosts
fi                  

imv ~/Pictures/system/Study\ times.png   # Open study schedule

hyprctl dispatch dpms on                 # Turn display on

cd ~/nixos-config                       
git fetch