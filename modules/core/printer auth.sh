#!/usr/bin/env bash

# UC FindMe Printer Authentication Setup
# This configures SMB credentials for authenticated printing

set -e

echo "UC FindMe Printer Authentication Setup"
echo "======================================="
echo

# Get UC credentials
read -p "Enter your UC username (without uocnt\\): " UC_USERNAME
read -sp "Enter your UC password: " UC_PASSWORD
echo
echo

# Create the auth file
AUTH_FILE="/etc/samba/user"

echo "Creating authentication file..."
sudo mkdir -p /etc/samba
sudo bash -c "cat > $AUTH_FILE" << EOF
username=$UC_USERNAME
password=$UC_PASSWORD
domain=UOCNT
EOF

# Secure the file (only root can read)
sudo chmod 600 $AUTH_FILE
sudo chown root:root $AUTH_FILE

echo "✓ Authentication file created"
echo

# Reconfigure printers with authentication
echo "Reconfiguring printers with authentication..."

# Remove existing printers
sudo lpadmin -x FindMe-BW 2>/dev/null || true
sudo lpadmin -x FindMe-Colour 2>/dev/null || true

# Re-add with authentication
sudo lpadmin -p FindMe-BW \
    -v "smb://UOCNT/$UC_USERNAME@printers.canterbury.ac.nz/FindMe-BW" \
    -m "foomatic-db/Ricoh/PS/Ricoh-IM_C2010_PS.ppd.gz" \
    -D "UC FindMe Black & White" \
    -L "UC Campus - Any Printer" \
    -o auth-info-required=username,password \
    -E

sudo lpadmin -p FindMe-Colour \
    -v "smb://UOCNT/$UC_USERNAME@printers.canterbury.ac.nz/FindMe-Colour" \
    -m "foomatic-db/Ricoh/PS/Ricoh-IM_C2010_PS.ppd.gz" \
    -D "UC FindMe Colour" \
    -L "UC Campus - Any Printer" \
    -o auth-info-required=username,password \
    -E

# Set default
sudo lpadmin -d FindMe-BW

# Enable printers
sudo cupsenable FindMe-BW
sudo cupsenable FindMe-Colour
sudo cupsaccept FindMe-BW
sudo cupsaccept FindMe-Colour

echo "✓ Printers reconfigured"
echo

# Clear any stuck jobs
sudo cancel -a 2>/dev/null || true

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Setup complete!"
echo
echo "Your credentials have been stored securely."
echo "Try printing again:"
echo "  lp -d FindMe-BW document.pdf"
echo
echo "If you still have issues, you may need to provide"
echo "credentials interactively on first print."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"