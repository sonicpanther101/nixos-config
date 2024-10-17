#!/usr/bin/env bash

############################################################
# Help                                                     #
############################################################

Help()
{
   # Display Help
   echo
   echo "Syntax: scriptTemplate [-n|a|H|h]"
   echo "options:"
   echo "n     Don't check for changes."
   echo "a     Restart ags."
   echo "H     Select host. laptop or desktop [l|d]. Required."
   echo "h     Print this Help."
}

no_check=false
ags=false
message=""

while getopts "anhH:m:" option; do  # anhH
    case $option in
        h) # display Help
            Help
            exit;;
        n) 
            no_check=true;;
        a) 
            ags=true;;
        m)
            message="$OPTARG"
            ;;
        H)
            echo "host: $OPTARG"
            case $OPTARG in
                l) 
                    host="laptop";;
                d) 
                    host="desktop";;
            esac;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
    esac
done

echo "message: $message"

set -e

if [[ $host == "" ]]; then
    echo "Please specify a host (laptop or desktop). [l|d]"
    exit 0
fi

# Vars
username='adam'

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

install() {
    echo -e "\n${RED}START INSTALL PHASE${NORMAL}\n"

    # Build the system (flakes + home manager)
    echo -e "\nBuilding the system...\n"
    nh os switch -H ${host} ./
}

pushd "/home/${username}/nixos-config"

# Early return if no changes were detected (thanks @singiamtel!)
if [[ $no_check == false ]] && git diff --quiet '*'; then
    echo "No changes detected, exiting."
    popd
    exit 0
fi

if [[ $no_check == false ]]; then
    git diff -U0 '*'
fi

if nmcli | grep "wlp2s0: connected"; then
    echo "Wifi connected, continuing..."
else
    echo "Wifi not connected, exiting."
    popd
    exit 0
fi

git fetch

if git status -uno | grep "Your branch is up to date with 'origin/main'."; then
    echo "Up to date, continuing..."
else
    echo "Not up to date, please pull, exiting."
    popd
    exit 0
fi

git add .

if [ -e "flake.lock" ]; then
    rm flake.lock
fi

if [[ $host == "laptop" ]]; then
    cp flake-laptop.lock flake.lock
elif [[ $host == "desktop" ]]; then
    cp flake-desktop.lock flake.lock
fi

install

if [[ $host == "laptop" ]]; then
    rm flake-laptop.lock
    mv flake.lock flake-laptop.lock
elif [[ $host == "desktop" ]]; then
    rm flake-desktop.lock
    mv flake.lock flake-desktop.lock
fi

current=$(nixos-rebuild list-generations | grep current)
changes=$(git diff --name-only)

if [[ $message != "" ]]; then
    git commit -am "${message} Rebuilt ${host} with new flake version ${current}. Updated files: ${changes}"
else
    git commit -am "Rebuilt ${host} with new flake version ${current}. Updated files: ${changes}"
fi

git push -u origin main

if [[ $ags == true ]]; then
    echo "Restarting AGS"
    my-ags
fi

popd

notify-send -e "NixOS Rebuilt OK\!" --icon=check-filled