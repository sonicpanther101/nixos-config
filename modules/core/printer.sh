#!/usr/bin/env bash

# UC FindMe Printer Setup Script for NixOS
# This adds FindMe-BW and FindMe-Colour printers using the Ricoh IM C2010 driver

set -e

PRINTER_SERVER="printers.canterbury.ac.nz"
DRIVER="foomatic-db/Ricoh/PS/Ricoh-IM_C2010_PS.ppd.gz"

echo "Setting up UC FindMe printers..."
echo

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "This script needs sudo privileges to add printers."
    echo "Please run: sudo bash setup-uc-printers.sh"
    exit 1
fi

# Function to add a printer
add_printer() {
    local name=$1
    local description=$2
    local location=$3
    
    echo "Adding printer: $name"
    
    # Remove printer if it exists
    lpadmin -x "$name" 2>/dev/null || true
    
    # Add the printer
    lpadmin -p "$name" \
        -v "smb://$PRINTER_SERVER/$name" \
        -m "$DRIVER" \
        -D "$description" \
        -L "$location" \
        -E
    
    # Enable the printer
    cupsenable "$name"
    cupsaccept "$name"
    
    echo "✓ $name added successfully"
    echo
}

# Add FindMe-BW (Black & White)
add_printer "FindMe-BW" \
    "UC FindMe Black & White" \
    "University of Canterbury - Any Campus Printer"

# Add FindMe-Colour
add_printer "FindMe-Colour" \
    "UC FindMe Colour" \
    "University of Canterbury - Any Campus Printer"

# Set FindMe-BW as default (cheaper for most printing)
lpadmin -d FindMe-BW

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Setup complete!"
echo
echo "Printers added:"
echo "  • FindMe-BW (default) - 5c/page B&W"
echo "  • FindMe-Colour - 15c/page colour"
echo
echo "Next steps:"
echo "1. Register your Canterbury Card at any FindMe printer"
echo "2. Print using: lp -d FindMe-BW document.pdf"
echo "3. Release print at any printer by waving your card"
echo
echo "Authentication may be required when you first print."
echo "Use your UC credentials: uocnt\\username"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"