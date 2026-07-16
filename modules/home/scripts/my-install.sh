#!/usr/bin/env zsh

Help()
{
   # Display Help
   echo
   echo "Syntax: scriptTemplate -[n|a|c|s|m|g|t|p|h]"
   echo "options:"
   echo "n     Don't check for changes" # Only needed when you want rebuild for changes that relied on an external file
   echo "a     Restart ags"
   echo "c     Fix corrupted db"
   echo "s     Skip install, just commit and push"
   echo "m     Git Commit Message"
   echo "g     Don't git commit"
   echo "t     Show error trace"
   echo "p     Launch shtris during the build"
   echo "h     Print this Help"
}

no_check=false
ags=false
message=""
corrupted_db=false
skip_install=false
skip_git=false
host=$(hostname)
show_trace=false
no_game=true

while getopts "anhtcsgpm:" option; do
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
        t)
            show_trace=true;;
        p)
            no_game=false;;
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
    sudo journalctl -u home-manager-${username}.service -n 20 --no-pager || true
}

# --- shtris split helpers -------------------------------------------------
shtris_win_id=""
shtris_prev_layout=""

start_shtris() {
    [[ $no_game == true ]] && return
    [[ -z "$KITTY_WINDOW_ID" ]] && return          # not inside kitty
    command -v shtris &> /dev/null || return       # shtris not installed
    command -v kitty &> /dev/null || return

    # --location=vsplit only produces a real left/right split when the
    # active layout is "splits" — remember the current layout so we can
    # switch to splits, then put it back when we're done.
    shtris_prev_layout=$(kitty @ ls 2> /dev/null \
        | grep -o '"layout_name": *"[^"]*"' | head -1 \
        | sed -E 's/.*"([^"]+)"$/\1/')

    kitty @ goto-layout splits &> /dev/null || true

    shtris_win_id=$(kitty @ launch \
        --type=window \
        --location=vsplit \
        --title="shtris" \
        shtris 2> /dev/null) || shtris_win_id=""

    if [[ -z "$shtris_win_id" ]]; then
        echo "(shtris: couldn't open split — is 'allow_remote_control yes' set in kitty.conf?)"
    fi
}

stop_shtris() {
    if [[ -n "$shtris_win_id" ]]; then
        kitty @ close-window --match id:$shtris_win_id &> /dev/null || true
        shtris_win_id=""
    fi
    if [[ -n "$shtris_prev_layout" ]]; then
        kitty @ goto-layout "$shtris_prev_layout" &> /dev/null || true
        shtris_prev_layout=""
    fi
}

# --- sudo keepalive ---------------------------------------------------------
# shtris takes keyboard focus once it opens, so if the build prompts for a
# sudo password AFTER that point there's no way to type it in without
# killing shtris first. Fix: authenticate sudo up front (while the main
# terminal still has focus) and keep the credential cache refreshed in the
# background so nothing inside the build ever has to prompt again.
sudo_refresh_pid=""

start_sudo_keepalive() {
    sudo -v || return 1
    ( while true; do sudo -n true; sleep 60; done ) 2> /dev/null &
    sudo_refresh_pid=$!
}

stop_sudo_keepalive() {
    if [[ -n "$sudo_refresh_pid" ]]; then
        kill "$sudo_refresh_pid" &> /dev/null || true
        wait "$sudo_refresh_pid" 2> /dev/null || true
        sudo_refresh_pid=""
    fi
}
# ---------------------------------------------------------------------------

# Safety net: no matter how/where the script exits (normal completion,
# `exit 0` early-outs, Ctrl-C, kill), make sure the shtris split and the
# sudo keepalive loop both get cleaned up. Both are no-ops if never started.
trap 'stop_shtris; stop_sudo_keepalive' EXIT
trap 'stop_shtris; stop_sudo_keepalive; exit 130' INT TERM
# ---------------------------------------------------------------------------

install() {
    echo -e "\n${RED}START INSTALL PHASE${NORMAL}\n"

    local nh_cmd="nh os switch -H ${host} ./"
    [[ $show_trace == true ]] && nh_cmd+=" -- --show-trace"
    [[ $corrupted_db == true ]] && nh_cmd="sudo nixos-rebuild switch --repair --flake .#${host}"

    # Prompt for the sudo password NOW, while the main terminal still has
    # focus, so shtris never grabs focus before you've had a chance to type it.
    start_sudo_keepalive
    start_shtris

    if ! eval "$nh_cmd"; then
        # Only show HM journal if HM service specifically failed, not nix build errors
        if systemctl is-failed --quiet home-manager-${username}.service 2>/dev/null; then
            echo -e "\n${RED}Home Manager failed — showing last 20 log lines${NORMAL}\n"
            journalctl -xe --unit home-manager-${username}.service -n 20 --no-pager || true
        fi
        exit 1
    fi

    stop_shtris          # close it as soon as the build's done, don't wait for git commit/push
    stop_sudo_keepalive
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
git reset > /dev/null
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
    vared -p "" message
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
    message="${message:0:1:u}${message:1}" # Capitalize first character

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

notify-send -t 2000 -e "NixOS Rebuilt OK" --icon=check-filled
