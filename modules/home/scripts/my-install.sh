#!/usr/bin/env bash

Help()
{
   # Display Help
   echo
   echo "Syntax: scriptTemplate [-n|a|c|m|h]"
   echo "options:"
   echo "n     Don't check for changes" # Only needed when you want rebuild for changes that relied on an external file
   echo "a     Restart ags"
   echo "c     Fix corrupted db"
   echo "m     Git Commit Message"
   echo "h     Print this Help"
}

no_check=false
ags=false
message=""
corrupted_db=false
host=$(hostname)

while getopts "anhm:" option; do
    case $option in
        h) # display Help
            Help
            exit;;
        n) 
            no_check=true;;
        a) 
            ags=true;;
        c) 
            corrupted_db=true;;
        m)
            message="$OPTARG";;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
    esac
done

set -e

# Vars
username='adam'

# Colors
NORMAL=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)

install() {
    echo -e "\n${RED}START INSTALL PHASE${NORMAL}\n"

    if [[ $corrupted_db == true ]]; then
        echo -e "\n${RED}FIXING CORRUPTED DB${NORMAL}\n"
        sudo nixos-rebuild switch --repair --flake .#${host}
    else
        # Build the system (flakes + home manager)
        echo -e "\nBuilding the system...\n"
        nh os switch -H ${host} ./
    fi
}

pushd "/home/${username}/nixos-config"

# 1. Check network FIRST (fail fast)
if ping -c 1 -W 2 1.1.1.1 > /dev/null 2>&1; then
    echo "Network connected, continuing..."
else
    echo "No network connection, exiting."
    popd
    exit 0
fi

# 2. Check git status
git fetch

if git status -uno | grep "Your branch is up to date with 'origin/master'."; then
    echo "Git is up to date, continuing..."
else
    if git status -uno | grep "Your branch is ahead of"; then
        echo "Git is ahead of cloud, continuing..."
    else
        echo "Not up to date, please pull, exiting."
        popd
        exit 0
    fi
fi

# 3. Check for changes
if [[ $no_check == false ]] && git diff --quiet '*'; then
    echo "No changes detected, exiting."
    popd
    exit 0
fi

if [[ $no_check == false ]]; then
    echo
    git diff -U0 '*'
    echo
fi

# 4. Get commit message (after confirming there are changes)
if [[ $message == "" ]]; then
    echo "Please write a git commit message:"
    read -r message
    if [[ $message == "" ]]; then
        echo "No message provided, exiting."
        popd
        exit 0
    fi
fi

echo "message: $message"

# 5. Stage changes BEFORE building
git add .

changes=$(git diff --cached --name-only | tr '\n' ' ')  # Use --cached to see staged changes

# 6. Build the system
install

# 7. Commit and push (with error handling)
echo "Getting generation info..."
current=$(nixos-rebuild list-generations 2>/dev/null | grep current) || current="unknown"

echo "Committing changes..."
git commit -m "${message}. Rebuilt ${host}: ${current}"

echo "Pushing to origin..."
git push -u origin master

# 8. Optional AGS restart
if [[ $ags == true ]]; then
    echo "Restarting AGS"
    my-ags
fi

popd

notify-send -e "NixOS Rebuilt OK!" --icon=check-filled