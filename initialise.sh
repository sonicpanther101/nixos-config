# install nixos and select no display manager when installing
# nmcli device wifi connect wifi_name password wifi_password
# nix-shell -p git nh
# git clone https://github.com/sonicpanther101/nixos-config
# cd nixos-config
# ./initialise.sh

mkdir -p ~/Music
mkdir -p ~/Pictures/wallpapers

cp /etc/nixos/hardware-configuration.nix hosts/${HOST}/hardware-configuration.nix