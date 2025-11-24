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

while getopts "anhm:" option; do  # anhH
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

echo "message: $message"

set -e

if [[ $message == "" ]]; then
    echo "Please write a git commit message:"
    read -r message
    if [[ $message == "" ]]; then
        echo "No message provided, exiting."
        popd
        exit 0
    fi
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

    if [[ $corrupted_db == true ]]; then
        echo -e "\n${RED}FIXING CORRUPTED DB${NORMAL}\n"
        sudo nixos-rebuild switch --repair --flake .#${host}
    else
        # Build the system (flakes + home manager)
        echo -e "\nBuilding the system...\n"
        nh os switch -H ${host} ./
    fi
}

pushd "/home/${username}/nixos-config" > /dev/null

# Early return if no changes were detected (thanks @singiamtel!)
if [[ $no_check == false ]] && git diff --quiet '*'; then
    echo "No changes detected, exiting."
    popd > /dev/null
    exit 0
fi

if [[ $no_check == false ]]; then
    git diff -U0 '*'
fi

if ping -c 1 -W 2 1.1.1.1 > /dev/null 2>&1; then
    echo "Network connected, continuing..."
else
    echo "No network connection, exiting."
    popd > /dev/null
    exit 0
fi

git fetch

if git status -uno | grep "Your branch is up to date with 'origin/main'."; then
    echo "Git is up to date, continuing..."
else
    echo "Not up to date, please pull, exiting."
    popd > /dev/null
    exit 0
fi

git add .

install

current=$(nixos-rebuild list-generations | grep current)
changes=$(git diff --name-only | tr '\n' ' ')

git commit -am "${message} Rebuilt ${host} with new flake version ${current}. Updated files: ${changes}"

git push -u origin main

if [[ $ags == true ]]; then
    echo "Restarting AGS"
    my-ags
fi

popd > /dev/null

notify-send -e "NixOS Rebuilt OK!" --icon=check-filled