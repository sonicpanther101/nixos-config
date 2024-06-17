#!/usr/bin/env bash

set -e

init() {
    # Vars
    CURRENT_USERNAME='frostphoenix'

    # Colors
    NORMAL=$(tput sgr0)
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
}

confirm() {
    echo -en "[${GREEN}y${NORMAL}/${RED}n${NORMAL}]: "
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 0
    fi
}

print_header() {
    echo -E "$CYAN
      _____              _   ____  _                      _        
     |  ___| __ ___  ___| |_|  _ \| |__   ___   ___ _ __ (_)_  __  
     | |_ | '__/ _ \/ __| __| |_) | '_ \ / _ \ / _ \ '_ \| \ \/ /  
     |  _|| | | (_) \__ \ |_|  __/| | | | (_) |  __/ | | | |>  <   
     |_|  |_|  \___/|___/\__|_|   |_| |_|\___/ \___|_| |_|_/_/\_\  
     _   _ _       ___        ___           _        _ _           
    | \ | (_)_  __/ _ \ ___  |_ _|_ __  ___| |_ __ _| | | ___ _ __ 
    |  \| | \ \/ / | | / __|  | || '_ \/ __| __/ _' | | |/ _ \ '__|
    | |\  | |>  <| |_| \__ \  | || | | \__ \ || (_| | | |  __/ |   
    |_| \_|_/_/\_\\\\___/|___/ |___|_| |_|___/\__\__,_|_|_|\___|_| 


                  $BLUE https://github.com/Frost-Phoenix $RED 
      ! To make sure everything runs correctly DONT run as root ! $GREEN
                        -> '"./install.sh"' $NORMAL

    "
}

get_username() {
    username="adam"  # Set username to a fixed value
    echo -en "Using username: $username\n"
}

set_username() {
    sed -i -e "s/${CURRENT_USERNAME}/${username}/g" ./flake.nix
    sed -i -e "s/${CURRENT_USERNAME}/${username}/g" ./modules/home/audacious/config
}

get_host() {
    echo -en "Choose a ${GREEN}host${NORMAL} - [${YELLOW}D${NORMAL}]esktop, [${YELLOW}L${NORMAL}]aptop or [${YELLOW}V${NORMAL}]irtual machine: "
    read -n 1 -r
    echo

    if [[ $REPLY =~ ^[Dd]$ ]]; then
        HOST='desktop'
    elif [[ $REPLY =~ ^[Ll]$ ]]; then
        HOST='laptop'
     elif [[ $REPLY =~ ^[Vv]$ ]]; then
        HOST='vm'
    else
        echo "Invalid choice. Please select 'D' for desktop, 'L' for laptop or 'V' for virtual machine."
        exit 1
    fi
    
    echo -en "$NORMAL"
    echo -en "Use the$YELLOW "$HOST"$NORMAL ${GREEN}host${NORMAL} ? "
    confirm
}

install() {
    echo -e "\n${RED}START INSTALL PHASE${NORMAL}\n"
    sleep 0.2

    # Last Confirmation
    echo -en "You are about to start the system build, do you want to process ? "
    confirm

    # Build the system (flakes + home manager)
    echo -e "\nBuilding the system...\n"
    sudo nixos-rebuild switch --flake .#${HOST} #&>nixos-switch.log || (cat nixos-switch.log | grep --color error && exit 1)
}

main() {

    # Early return if no changes were detected (thanks @singiamtel!)
    #if git diff --quiet '*.nix'; then
    #    echo "No changes detected, exiting."
    #    popd
    #    exit 0
    #fi

    # Shows your changes
    #git diff -U0 '*.nix'

    init

    #print_header

    get_username
    set_username
    get_host

    install

    # Get current generation metadata
    current=$(nixos-rebuild list-generations | grep current)

    # Commit all changes witih the generation metadata
    git commit -am "$current"

    # Notify all OK!
    notify-send -e "NixOS Rebuilt OK!" --icon=software-update-available
}

main && exit 0
