#!/usr/bin/env bash

WIFI_DEV="wlp109s0"

USB_DEV=$(
    ip -4 -o addr show |
    awk '$4 ~ /^172\./ {print $2; exit}'
)

if [ -n "$USB_DEV" ]; then
    USB_IP=$(ip -4 -o addr show dev "$USB_DEV" | awk '{split($4,a,"/"); print a[1]}')
    PHONE_IP=$(ip route show dev "$USB_DEV" | awk '/default via/ {print $3}')
fi

WIFI_IP=$(ip -4 -o addr show dev "$WIFI_DEV" 2>/dev/null | awk '{split($4,a,"/"); print a[1]}')

echo "=== Syncthing over USB Tether ==="
echo

if [ -n "$USB_DEV" ]; then
    echo "USB interface: $USB_DEV"
    echo
    echo "On your computer, set phone address to:"
    echo "  tcp://$PHONE_IP:22000"
    echo
    echo "On your phone, set computer address to:"
    echo "  tcp://$USB_IP:22000"
else
    echo "No USB tether interface found — is the phone plugged in and tethering enabled?"
fi

if [ -n "$WIFI_IP" ]; then
    echo
    echo "(WiFi also available at $WIFI_IP if needed)"
fi