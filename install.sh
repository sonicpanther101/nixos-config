#!/usr/bin/env bash

#--------------------#
#   Initialisation   #
#--------------------#

CURRENT_USERNAME='adam'

RESET=$(tput sgr0)
WHITE=$(tput setaf 7)
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BRIGHT=$(tput bold)
UNDERLINE=$(tput smul)

OK="[${GREEN}OK${RESET}]\t"
INFO="[${BLUE}INFO${RESET}]\t"
WARN="[${MAGENTA}WARN${RESET}]\t"
ERROR="[${RED}ERROR${RESET}]\t"

set -e

#------------------------------#
#   Check if running as root   #
#------------------------------#

if [[ $EUID -eq 0 ]]; then
    echo -e "${ERROR}This script should ${RED}NOT${RESET} be executed as root!"
    echo -e "${INFO}Exiting..."
    exit 1
fi

#------------------------------------#
#   Check if whiptail is installed   #
#------------------------------------#

if ! command -v whiptail &> /dev/null; then
    echo -e "${INFO}whiptail not found, downloading required packages"
    nix-shell -p newt --run "$(realpath "$0")"
    exit $?
fi

clear

echo -E "$CYAN
   _____             _                        _   _              __  ___  __ 
  / ____|           (_)                      | | | |            /_ |/ _ \/_ |
 | (___   ___  _ __  _  ___ _ __   __ _ _ __ | |_| |__   ___ _ __| | | | || |
  \___ \ / _ \| '_ \| |/ __| '_ \ / _\` | \'_\| __| '_  \\/ _ \\ '__| | | | || |
  ____) | (_) | | | | | (__| |_) | (_| | | | | |_| | | |  __/ |  | | |_| || |
 |_____/ \___/|_| |_|_|\___| .__/ \__,_|_| |_|\__|_| |_|\___|_|  |_|\___/ |_|
                           | |                                               
                           |_|                                               
     _   _ _       ___        ___           _        _ _           
    | \ | (_)_  __/ _ \ ___  |_ _|_ __  ___| |_ __ _| | | ___ _ __ 
    |  \| | \ \/ / | | / __|  | || '_ \/ __| __/ _' | | |/ _ \ '__|
    | |\  | |>  <| |_| \__ \  | || | | \__ \ || (_| | | |  __/ |   
    |_| \_|_/_/\_\\\\___/|___/ |___|_| |_|___/\__\__,_|_|_|\___|_| 


       ${BLUE} ─── https://github.com/sonicpanther101/nixos-config ─── ${RESET}
"

#------------------#
#   Get username   #
#------------------#

while true; do
    username=$(whiptail --inputbox "Enter your username:" 9 40 --title "Username" 3>&1 1>&2 2>&3)

    if [ $? != 0 ]; then
        exit 1
    fi

    if ! [[ $username =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
        whiptail --msgbox "Invalid username: '$username'" 8 40 --title Error 3>&1 1>&2 2>&3
        continue
    fi

    if (whiptail --yesno "Use '$username' as username?" 8 40 --title "Confirm Username"); then
        break
    fi
done

#-----------------#
#   Choose host   #
#-----------------#

while true; do
    HOST=$(whiptail --radiolist "Choose a host:" 11 48 4 \
        "new" "New configuration" ON \
        "desktop" "Desktop configuration" OFF \
        "laptop" "Laptop configuration" OFF \
        "laptop-2" "Laptop-2 configuration" OFF \
        --title "Host" 3>&1 1>&2 2>&3)

    if [ $? != 0 ]; then
        exit 1
    fi

    if (whiptail --yesno "Use the '$HOST' host?" 8 40 --title "Confirm Host"); then
        break
    fi
done

newHost=""
if [ HOST == "new" ]; then
    while true; do
        newHost=$(whiptail --inputbox "Enter your new host name (cannot be an existing one):" 8 40 --title "Host Name" 3>&1 1>&2 2>&3)

        if [ $? != 0 ]; then
            exit 1
        fi

        if (whiptail --yesno "Use '$newHost' as new host name?" 8 40 --title "Confirm Host Name"); then
            break
        fi
    done
    HOST=$newHost

    while true; do
        swapSize=$(whiptail --inputbox "Enter your new host swap size (GB) (set aside storage for sleep):" 8 40 --title "Swap Size" 3>&1 1>&2 2>&3)

        if [ $? != 0 ]; then
            exit 1
        fi

        if (whiptail --yesno "Use '$swapSize' as new host swap size (GB)?" 8 40 --title "Confirm Swap Size"); then
            break
        fi
    done
fi

#---------------------------#
#     Enter git details     #
#---------------------------#

while true; do
    gitname=$(whiptail --inputbox "Enter your git username/name:" 9 40 --title "Name" 3>&1 1>&2 2>&3)

    if [ $? != 0 ]; then
        exit 1
    fi

    if (whiptail --yesno "Use '$gitname' as git name? (shows up in commits)" 8 40 --title "Confirm Name"); then
        break
    fi
done

while true; do
    gitemail=$(whiptail --inputbox "Enter your git email:" 9 40 --title "Email" 3>&1 1>&2 2>&3)

    if [ $? != 0 ]; then
        exit 1
    fi

    if (whiptail --yesno "Use '$gitemail' as email? (shows up in commits)" 8 40 --title "Confirm Email"); then
        break
    fi
done

#---------------------------#
#   Recap of user choices   #
#---------------------------#

SUMMARY="\
Username:   $username
Host:       $HOST
Git Name:   $gitname
Git Email:  $gitemail
"

whiptail --msgbox "$SUMMARY" 11 40 --title "Installation Summary"

#-----------------------#
#   Last Confirmation   #
#-----------------------#

if ! (whiptail --yesno "You are about to build the system for host '$HOST'. Proceed?" 9 40 --title "Final Confirmation"); then
    exit 0
fi

#---------------------#
#    Change names     #
#---------------------#

echo -e "${INFO}Changing username to ${GREEN}$username${RESET}"
sed -i "s/${CURRENT_USERNAME}/${username}/g" flake.nix

if [ newHost ]; then
    sed -i -z "s|\(.*\)      };|\1      };\
        \n      ${HOST} = nixpkgs-unstable.lib.nixosSystem {\
        \n              inherit system;\
        \n        modules = [\
        \n          ./hosts/${HOST}\
        \n          inputs.grub2-themes.nixosModules.default\
        \n          inputs.stylix.nixosModules.stylix\
        \n          inputs.nix-index-database.nixosModules.default\
        \n        ];\
        \n        specialArgs = {\
        \n          host = \"${HOST}\";\
        \n          inherit self inputs username pkgs-stable pkgs-unstable;\
        \n        };\
        \n      };|" flake.nix
fi

#----------------------#
#   Clear git config   #
#----------------------#

echo -e "${INFO}Changing git account details"
sed -i "s/\"sonicpanther101\"/\"${gitname}\"/g" modules/home/git.nix
sed -i "s/\"sonicpanther101@gmail.com\"/\"${gitemail}\"/g" modules/home/git.nix

#------------------------------#
#   Prepare the environement   #
#------------------------------#

## Create common dirrectories
echo -e "${INFO}Preparing the environment"
for dir in ~/Music ~/Documents ~/Pictures; do
    echo -e "${INFO}Creating folder: ${MAGENTA}${dir}${RESET}"
    mkdir -p "$dir"
done

## Copy wallpapers
echo -e "${INFO}Copying wallpapers..."
cd ~/Pictures
git clone https://github.com/sonicpanther101/wallpapers
cd ~/nixos-config

## Get the hardware configuration
if [ ! -f /etc/nixos/hardware-configuration.nix ]; then
    echo -e "${ERROR} ${MAGENTA}/etc/nixos/hardware-configuration.nix${RESET} not found! Aborting."
    whiptail --msgbox "/etc/nixos/hardware-configuration.nix not found! Aborting." 9 40 --title "Error"
    exit 1
fi
echo -e "${INFO}Copying ${MAGENTA}/etc/nixos/hardware-configuration.nix${RESET} to ${MAGENTA}./hosts/${HOST}/${RESET}"
if [ newHost ]; then
    mkdir -p hosts/${HOST}
    cp hosts/desktop/default.nix hosts/${HOST}/default.nix
    git add .
fi
cp /etc/nixos/hardware-configuration.nix hosts/${HOST}/hardware-configuration.nix

## Create swap file for sleeping
if [ newHost ]; then
    echo -e "${INFO}Setting up sleep for new host ${MAGENTA}${HOST}${RESET}"
    sed -i -z "s|swapDevices = \[ \];|swapDevices = [{\
\n    device = \"/swapfile\";\
\n    size = ${swapSize} * 1024; # ${swapSize}GB\
\n  }];|" hosts/${HOST}/hardware-configuration.nix
fi

#------------------#
#   Installation   #
#------------------#

echo -e "${INFO}Starting system build... this may take a while."
sudo nixos-rebuild switch --flake .#${HOST}

echo -e "${INFO}System build finished successfully"

if [ newHost ]; then
    echo -e "${INFO}Finishing setting up sleep"
    physicalOffset=$(sudo filefrag -v /swapfile | head | grep " 0: " | tr -s '[:space:]' '\n' | head -n 5 | tail -n 1)
    physicalOffset=$(echo ${physicalOffset::-2})
    uuid=$(lsblk -f | grep "/nix/store" | tr -s '[:space:]' '\n' | tail -n 4 | head -n 1)

    perl -0pi -e "s|swapDevices = \[\{\s*
\s*device = \"/swapfile\";
\s*size = ${swapSize} \* 1024; # ${swapSize}GB
\s*\}\];|swapDevices = [{
    device = \"/swapfile\";
    size = ${swapSize} * 1024; # ${swapSize}GB
  }];

  boot.kernelParams = [ \"mem_sleep_default=deep\" \"resume_offset=${physicalOffset}\" ];

  boot.resumeDevice = \"/dev/disk/by-uuid/${uuid}\";|s" \
"hosts/${HOST}/hardware-configuration.nix"

    echo -e "${INFO}Starting second system build to enable sleep... this one should be quicker."
    sudo nixos-rebuild switch --flake .#${HOST}
fi

echo -e "${INFO}Setting up my-install script"
git remote set-url origin git@github.com:${gitname}/nixos-config.git
ssh-keygen -t ed25519 -C "${gitemail}"
key=$(cat ~/.ssh/id_ed25519.pub | tr -s '[:space:]' '\n' | head -n 2 | tail -n 1 )
echo -e "${INFO}Copy this key:\nssh-ed25519 ${key}\nThen add the public key to GitHub: Account Settings → SSH and GPG keys → New SSH key"

echo -e "${INFO}You can now reboot to apply the config"
echo -e "${INFO}After you reboot, make sure to set up any specialised hardware by looking in the ./modules/core/hardware.nix and changing some of the host checking stakements throughout the config"