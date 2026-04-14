host=$(hostname)                        

if [[ $host == "desktop" ]]; then       
    openrgb --mode direct --color 000000 # Turn all RGB off, without opening openrgb
fi                                      

playerctl pause                          # Pause all media

pidof swaylock || swaylock --daemonize   # Display lockscreen on wakeup

sleep 0.5

pkill hypridle && systemctl suspend      # Put to sleep

if [[ $host == "desktop" ]]; then       
    openrgb --mode direct --color 000000 # Turn all RGB off if started on boot
fi                  

imv ~/Pictures/system/Study\ times.png   # Open study schedule

hyprctl dispatch dpms on                 # Turn display on

cd ~/nixos-config && git fetch