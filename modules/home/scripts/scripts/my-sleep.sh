if ps aux | grep openrgb | grep -v S+ > /dev/null; then
    sudo pkill openrgb
    openrgb --mode static --color 000000
fi
systemctl suspend
swaylock
openrgb --mode static --color 000000