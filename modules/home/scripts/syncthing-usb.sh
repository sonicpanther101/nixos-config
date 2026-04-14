#!/usr/bin/env bash

USB_DEV="enp0s20f0u6"
WIFI_DEV="wlp109s0"

USB_IP=$(ip addr show "$USB_DEV" 2>/dev/null | awk '/inet / {split($2,a,"/"); print a[1]}')
PHONE_IP=$(ip route show dev "$USB_DEV" | awk '/default via/ {print $3}')
WIFI_IP=$(ip addr show "$WIFI_DEV" 2>/dev/null | awk '/inet / {split($2,a,"/"); print a[1]}')

echo "=== Syncthing over USB Tether ==="
echo ""

if [ -n "$USB_IP" ]; then
    echo "On your computer, set phone address to:"
    echo "  tcp://$PHONE_IP:22000"
    echo ""
    echo "On your phone, set computer address to:"
    echo "  tcp://$USB_IP:22000"
else
    echo "USB tether interface ($USB_DEV) not found — is the phone plugged in and tethering enabled?"
fi

if [ -n "$WIFI_IP" ]; then
    echo ""
    echo "(WiFi also available at $WIFI_IP if needed)"
fi