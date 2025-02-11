# install nixos and select no display manager when installing
# nmcli device wifi connect wifi_name password wifi_password
# nix-shell -p git nh
# git clone https://github.com/sonicpanther101/nixos-config
# cd nixos-config
# chmod +x ./*
# ./initialise.sh -U username -H l or d -m "optional message"

mkdir -p ~/Music
mkdir -p ~/Pictures/wallpapers
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

while getopts "U:H:m:" option; do  # anhH
    case $option in
        m)
            message="$OPTARG"
            ;;
        H)
            echo "host: $OPTARG"
            case $OPTARG in
                l) 
                    host="laptop"
                    h="l";;
                d) 
                    host="desktop"
                    h="d";;
            esac;;
        U)
            echo "username: $OPTARG"
            username="$OPTARG";;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
    esac
done

sed -i -e "s/adam/${username}/g" ./flake.nix

cp /etc/nixos/hardware-configuration.nix hosts/${host}/hardware-configuration.nix

./modules/home/scripts/scripts/my-install.sh -n -H ${h} -m "${message}"