host=$(hostname)                                           

if [[ $host == "desktop" ]]; then                          

    if ps aux | grep openrgb | grep -v S+ > /dev/null; then # Check if openrgb is running
        sudo pkill openrgb                                  # Close existing openrgb
    fi                                                     

    openrgb --mode direct --color 000000                    # Turn all RGB off, without opening openrgb
fi                                                         

shutdown -h now                                             # Actually shut down