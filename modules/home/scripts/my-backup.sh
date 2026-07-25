if lsblk | grep Ventoy; then
    cp /run/media/adam/Ventoy/Uni\ Notes /tmp/usb-backup
    rm ~/Desktop/Uni\ Notes
    mv /tmp/usb-backup ~/Desktop/Uni\ Notes
    echo "Last backed up $(date '+%l:%M%p')"
fi
