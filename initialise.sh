# install nixos and select no display manager when installing
# nmcli device wifi connect wifi_name password wifi_password
# nix-shell -p git nh
# git clone https://github.com/sonicpanther101/nixos-config
# cd nixos-config
# ./initialise.sh

mkdir -p ~/Music
mkdir -p ~/Pictures/wallpapers

while getopts "anhH:m:" option; do  # anhH
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
        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
    esac
done

cp /etc/nixos/hardware-configuration.nix hosts/${host}/hardware-configuration.nix

./modules/home/scripts/scripts/my-install.sh -n -H ${h} -m "${message}"