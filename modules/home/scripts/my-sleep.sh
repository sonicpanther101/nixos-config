host=$(hostname)                                                                                       

if [[ $host == "desktop" ]]; then                                                                      

    if ps aux | grep openrgb | grep -v S+ > /dev/null; then # Check if openrgb is running              
        sudo pkill openrgb                                  # Close existing openrgb                   
    fi                                                                                                 

    openrgb --mode direct --color 000000                    # Turn all RGB off, without opening openrgb
fi                                                                                                     
playerctl pause                                             # Pause all media                        
systemctl suspend                                           # Put to sleep                           
hyprlock                                                    # Display lockscreen on wakeup           

if [[ $host == "desktop" ]]; then                                                                
    openrgb --mode direct --color 000000                    # Turn all RGB off if started on boot
fi                                                                                                     
