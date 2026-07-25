if lsblk | grep Ventoy >/dev/null 2>&1; then
    cp -r /run/media/adam/Ventoy/Uni\ Notes /tmp/usb-backup
    rm -rf ~/Desktop/Uni\ Notes
    mv /tmp/usb-backup ~/Desktop/Uni\ Notes
    echo "Last backed up $(date '+%l:%M%p')"
fi
