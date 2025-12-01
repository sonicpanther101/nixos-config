#!/usr/bin/env bash

Help()
{
   # Display Help
   echo
   echo "Syntax: scriptTemplate -[n|a|c|s|m|g|h]"
   echo "options:"
   echo "n     Don't check for changes" # Only needed when you want rebuild for changes that relied on an external file
   echo "a     Restart ags"
   echo "c     Fix corrupted db"
   echo "s     Skip install, just commit and push"
   echo "m     Git Commit Message"
   echo "g     Don't git commit"
   echo "h     Print this Help"
}

no_check=false
ags=false
message=""
corrupted_db=false
skip_install=false
skip_git=false
host=$(hostname)

while getopts "anhcsgm:" option; do
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
        s)
            skip_install=true;;
        g)
            skip_git=true;;
        m)
            message="$OPTARG";;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
    esac
done

set -e

# Vars
username=$(whoami)

# Colors
NORMAL=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)

print_hm_logs() {
    echo -e "\n${RED}Home Manager failed — showing last 20 log lines${NORMAL}\n"
    sudo journalctl -u home-manager-adam.service -n 20 --no-pager || true
}

install() {
    echo -e "\n${RED}START INSTALL PHASE${NORMAL}\n"

    if [[ $corrupted_db == true ]]; then
        echo -e "${RED}FIXING CORRUPTED DB${NORMAL}\n"
        sudo nixos-rebuild switch --repair --flake .#${host}
    else
        # Build the system (flakes + home manager)
        echo -e "Building the system...\n"
        if ! nh os switch -H ${host} ./; then
            # Only print logs if the HM service failed
            systemctl status home-manager-${username}.service &>/dev/null
            if [[ $? -ne 0 ]]; then
                print_hm_logs
            else
                print_hm_logs
            fi
            exit 1
        fi
    fi
}

pushd "/home/${username}/nixos-config"  > /dev/null

# 1. Check network FIRST (fail fast)
if ping -c 1 -W 2 1.1.1.1 > /dev/null 2>&1; then
    echo "Network connected, continuing..."
else
    echo "No network connection, exiting."
    popd > /dev/null
    exit 0
fi

# 2. Check git status
git fetch 2>&1 | grep -v "redirecting to" || true

if git status -uno 2>&1 | grep -q "Your branch is up to date with 'origin/main'."; then
    echo "Git is up to date, continuing..."
else
    if git status -uno 2>&1 | grep -q "Your branch is ahead of"; then
        echo "Git is ahead of origin, continuing..."
    else
        echo "Not up to date, please pull, exiting."
        popd > /dev/null
        exit 0
    fi
fi

# 3. Check for changes
if [[ $no_check == false ]] && [[ $skip_git == false ]] && [[ $skip_install == false ]] && git diff --quiet '*'; then
    echo "No changes detected, exiting."
    popd > /dev/null
    exit 0
fi

# 4. Stage changes BEFORE building
git add .

echo # to account for no check
if [[ $no_check == false ]]; then
    git diff -U0 --cached '*'
    echo
fi

# 5. Get commit message (after confirming there are changes)
if [[ $message == "" ]] && [[ $skip_git == false ]]; then
    echo "Please write a git commit message:"
    read -r -e message
    if [[ $message == "" ]]; then
        echo "No message provided, exiting."
        popd > /dev/null
        exit 0
    fi
fi

changes=$(git diff --cached --name-only | tr '\n' ' ')  # Use --cached to see staged changes

# 6. Build the system
if [[ $skip_install == false ]]; then
    install
    echo

    current=$(nixos-rebuild list-generations 2>/dev/null | grep True | awk '{print "Generation", $1}') || current="Generation unknown"
else
    echo
    echo "Skipping install..."
    echo

    current="skipped"
fi

# 7. Commit and push
if [[ $skip_git == false ]]; then
    message="${message^}" # Capitalize first character

    commit_output=$(git commit -m "${message}. Rebuilt ${host}: ${current}" 2>&1)
    commit_hash=$(echo "$commit_output" | grep -oP '\[\w+ \K\w+(?=\])')

    echo -e "${GREEN}✓ Committed ${BLUE}${commit_hash}${NORMAL}: ${message}: ${current}"

    push_output=$(git push -u origin main 2>&1)

    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Pushed${NORMAL} to ${BLUE}origin/main"
    else
        echo -e "${RED}✗ Push failed${NORMAL}"
        exit 1
    fi
fi

# 8. Optional AGS restart
if [[ $ags == true ]]; then
    echo "Restarting AGS"
    my-ags
fi

popd > /dev/null

notify-send -e "NixOS Rebuilt OK!" --icon=check-filled