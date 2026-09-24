#!/usr/bin/env zsh

Help()
{
   echo
   echo "Syntax: scriptTemplate -[n|a|c|s|m|g|t|u|p|l|b|H|f|h]"
   echo "options:"
   echo "n     Don't check for changes"
   echo "a     Restart ags"
   echo "c     Fix corrupted db"
   echo "s     Skip install, just commit and push"
   echo "m     Git Commit Message"
   echo "g     Don't git commit"
   echo "t     Show error trace"
   echo "u     Git pull to update"
   echo "p     Launch shtris during the build"
   echo "l     Limit CPU/memory used for the rebuild"
   echo "b     Use 'nh os boot' instead of 'switch' (stage for next reboot, don't activate now)"
   echo "H     Home-manager only: build+activate just the home-manager part, skip the full system rebuild"
   echo "      (this is also applied automatically when the staged changes are all under modules/home/)"
   echo "f     Force a full system rebuild, even if the staged changes are all under modules/home/"
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
limit_resources=false
boot_mode=false
home_only=false
force_full=false
hm_generation=""

while getopts "anhtcsgpulbHfm:" option; do
    case $option in
        h)
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
        u)
            cd ~/nixos-config && git pull;;
        p)
            no_game=false;;
        l)
            limit_resources=true;;
        b)
            boot_mode=true;;
        H)
            home_only=true;;
        f)
            force_full=true;;
        m)
            message="$OPTARG";;
        \?)
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

    local nh_action="switch"
    [[ $boot_mode == true ]] && nh_action="boot"

    local nh_cmd="nh os ${nh_action} -H ${host} ./"
    local extra_args=()
    local cpu_weight=""
    local mem_max=""

    [[ $show_trace == true ]] && extra_args+=(--show-trace)

    if [[ $limit_resources == true ]]; then
        case ${host} in
            desktop)
                cpu_weight=20
                mem_max=16G
                extra_args+=(--max-jobs 4 --cores 4)
                ;;
            laptop)
                cpu_weight=20
                mem_max=6G
                extra_args+=(--max-jobs 2 --cores 2)
                ;;
            *)
                echo "${RED}No resource limits configured for host '${host}', running unrestricted.${NORMAL}"
                ;;
        esac
    fi

    if [[ $corrupted_db == true ]]; then
        # Repair always needs to activate now, so this ignores -b.
        [[ $boot_mode == true ]] && echo "${RED}Note: -c (repair) always activates now, ignoring -b.${NORMAL}"
        nh_cmd="sudo nixos-rebuild switch --repair --flake .#${host}"
    fi

    if (( ${#extra_args[@]} > 0 )); then
        nh_cmd+=" -- ${extra_args[*]}"
    fi

    if [[ -n "$cpu_weight" ]]; then
        nh_cmd="systemd-run --user --scope -p CPUWeight=${cpu_weight} -p MemoryMax=${mem_max} -- ${nh_cmd}"
    fi

    # Prompt for the sudo password NOW, while the main terminal still has
    # focus, so shtris never grabs focus before you've had a chance to type it.
    start_sudo_keepalive
    start_shtris

    if ! eval "$nh_cmd"; then
        if systemctl is-failed --quiet home-manager-${username}.service 2>/dev/null; then
            echo -e "\n${RED}Home Manager failed — showing last 20 log lines${NORMAL}\n"
            journalctl -xe --unit home-manager-${username}.service -n 20 --no-pager || true
        fi
        exit 1
    fi

    stop_shtris
    stop_sudo_keepalive

    if [[ $boot_mode == true ]] && [[ $corrupted_db == false ]]; then
        echo -e "\n${GREEN}Staged for next boot${NORMAL} — reboot to activate this generation.\n"
    fi
}

# --- home-manager-only rebuild ---------------------------------------------
# This config wires home-manager in as a NixOS module (see modules/core/user.nix),
# not as a standalone `homeConfigurations` flake output, so there's no
# `nh home switch` for it here. The equivalent trick for a module-based setup
# is to build just the user's home.activationPackage attribute out of the
# normal nixosConfiguration and run its activation script directly, which
# skips the (much slower) full system rebuild entirely.
home_manager_capable() {
    nix eval --quiet ".#nixosConfigurations.${host}.config.home-manager.users.${username}.home.activationPackage.drvPath" &> /dev/null
}

install_home() {
    echo -e "\n${RED}START HOME-MANAGER-ONLY INSTALL PHASE${NORMAL}\n"

    if ! home_manager_capable; then
        echo -e "${RED}Can't resolve a home-manager activationPackage for host '${host}' / user '${username}'.${NORMAL}"
        echo "Falling back to a full system rebuild."
        home_only=false
        install
        return
    fi

    local hm_attr=".#nixosConfigurations.${host}.config.home-manager.users.${username}.home.activationPackage"
    local out_link
    out_link="$(mktemp -u /tmp/my-install-hm-XXXXXX)"

    # Prefer `nom build` over plain `nix build` when it's available: it's the
    # same tree-style build progress view "nh" already gives you for full
    # system rebuilds (nh uses it internally), there's just no `nh home`
    # entry point for a module-based home-manager setup like this one.
    local build_cmd=(nix build "$hm_attr" -o "$out_link")
    command -v nom &> /dev/null && build_cmd=(nom build "$hm_attr" -o "$out_link")
    [[ $show_trace == true ]] && build_cmd+=(--show-trace)

    if ! "${build_cmd[@]}"; then
        rm -f "$out_link"
        echo -e "${RED}Home-manager build failed.${NORMAL}"
        exit 1
    fi

    local hm_path
    hm_path="$(readlink -f "$out_link")"
    rm -f "$out_link"

    # Best-effort: show what's changing, similar to what nh prints after a
    # switch. Silently skipped if nvd/the profile path aren't there — this is
    # a nice-to-have, not something the rebuild should depend on.
    command -v nvd &> /dev/null && nvd diff /home/${username}/.local/state/nix/profiles/home-manager "$hm_path" 2> /dev/null

    echo -e "${BLUE}Activating home-manager generation...${NORMAL}"
    if ! "${hm_path}/activate"; then
        if systemctl is-failed --quiet home-manager-${username}.service 2>/dev/null; then
            print_hm_logs
        fi
        exit 1
    fi

    # Grab the generation number that was just activated, so the commit
    # message has something concrete to debug against later (matches what
    # the full-rebuild path does with `nixos-rebuild list-generations`).
    hm_generation=$(nix-env -p "/home/${username}/.local/state/nix/profiles/home-manager" --list-generations 2>/dev/null | tail -1 | awk '{print $1}')

    if [[ -n "$hm_generation" ]]; then
        echo -e "${GREEN}Home-manager activated${NORMAL} (system generation untouched) — generation ${hm_generation}."
    else
        echo -e "${GREEN}Home-manager activated${NORMAL} (system generation untouched)."
    fi
}
# ---------------------------------------------------------------------------

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

# 5b. Auto-detect a home-manager-only change set (unless overridden with -H/-f)
if [[ $home_only == false ]] && [[ $force_full == false ]] && [[ -n "$changes" ]]; then
    only_home=true
    changed_files=("${(f)$(git diff --cached --name-only)}")
    for f in "${changed_files[@]}"; do
        case "$f" in
            modules/home/*) ;;
            *) only_home=false;;
        esac
        [[ $only_home == false ]] && break
    done
    if [[ $only_home == true ]]; then
        echo "Only modules/home/ changed — switching to a home-manager-only rebuild."
        home_only=true
    fi
fi

# -b/-c don't make sense for a home-manager-only rebuild, so fall back to a
# full one if either was requested alongside it.
if [[ $home_only == true ]] && [[ $boot_mode == true || $corrupted_db == true ]]; then
    echo "-b/-c require a full system rebuild — ignoring -H."
    home_only=false
fi

# 6. Build the system
if [[ $skip_install == false ]]; then
    if [[ $home_only == true ]]; then
        install_home
    else
        install
    fi
    echo

    if [[ $boot_mode == true ]] && [[ $corrupted_db == false ]]; then
        current="Generation staged (nh os boot), pending reboot"
    elif [[ $home_only == true ]]; then
        if [[ -n "$hm_generation" ]]; then
            current="Home-manager generation ${hm_generation}"
        else
            current="Home-manager only"
        fi
    else
        current=$(nixos-rebuild list-generations 2>/dev/null | grep True | awk '{print "Generation", $1}') || current="Generation unknown"
    fi
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
