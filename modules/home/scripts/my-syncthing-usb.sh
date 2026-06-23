#!/usr/bin/env bash

echo "=== Syncthing over USB Tether ==="
echo

# Find USB network interfaces (real USB bus devices only)
USB_DEVS=()

for dev in /sys/class/net/*; do
    iface=$(basename "$dev")

    # skip obvious non-USB interfaces
    [[ "$iface" == lo ]] && continue
    [[ "$iface" == docker0 ]] && continue
    [[ "$iface" == veth* ]] && continue
    [[ "$iface" == br-* ]] && continue
    [[ "$iface" == virbr* ]] && continue

    # check if interface is on USB bus
    if readlink -f "$dev/device" 2>/dev/null | grep -q "/usb"; then
        USB_DEVS+=("$iface")
    fi
done

if [ ${#USB_DEVS[@]} -eq 0 ]; then
    echo "No USB tether interface found."
    exit 1
fi

# use first USB tether interface
USB_DEV="${USB_DEVS[0]}"

USB_IP=$(ip -4 -o addr show dev "$USB_DEV" | awk '{split($4,a,"/"); print a[1]}')

# phone side = gateway on that USB link (if present)
PHONE_IP=$(ip route show dev "$USB_DEV" | awk '/default via/ {print $3}')

echo "USB interface: $USB_DEV"
echo

if [ -n "$PHONE_IP" ]; then
    echo "On your computer (connect to phone):"
    echo "  tcp://$PHONE_IP:22000"
else
    echo "On your computer (connect to phone):"
    echo "  tcp://<unknown-phone-ip>:22000"
fi

echo
echo "On your phone (connect to computer):"
echo "  tcp://$USB_IP:22000"set -euo pipefail
