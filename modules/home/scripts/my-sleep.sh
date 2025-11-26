if ps aux | grep openrgb | grep -v S+ > /dev/null; then # Check if openrgb is running              
    sudo pkill openrgb                                  # Close existing openrgb                   
fi                                                     
openrgb --mode direct --color 000000                    # Turn all RGB off, without opening openrgb
playerctl pause                                         # Pause all media                          
systemctl suspend                                       # Put to sleep                             
swaylock                                                # Display lockscreen on wakeup             
openrgb --mode direct --color 000000                    # Turn all RGB off if started on boot