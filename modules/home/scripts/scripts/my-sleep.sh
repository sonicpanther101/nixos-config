if hyprctl monitors -j | grep "DP"; then
    sudo pkill openrgb
    openrgb --mode static --color 000000
    sleep 0.5
fi
systemctl suspend
swaylock