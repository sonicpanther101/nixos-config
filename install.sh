#!/usr/bin/env bash

#--------------------#
#   Initialisation   #
#--------------------#

CURRENT_USERNAME='adam'
DEFAULT_GIT_NAME='sonicpanther101'
DEFAULT_GIT_EMAIL='sonicpanther101@gmail.com'

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

#-----------------------#
#   Command line flags  #
#-----------------------#

ORIG_ARGS=("$@")
RESET_STATE=false
REDO_STEPS=()

usage() {
    echo "Usage: ./install.sh [--reset] [--redo STEP]..."
    echo "  Run it again after a failed build and it carries on where it stopped,"
    echo "  using the answers you already gave."
    echo "  --reset      forget saved answers and progress and start over (edits already"
    echo "               made to the repo are kept, undo those with git if needed)"
    echo "  --redo STEP  repeat one finished step: config_edit, host_files, build, sleep, finished"
    echo "               (host_files regenerates the host's files, overwriting hand edits to them)"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --reset) RESET_STATE=true; shift;;
        --redo)
            if [[ -z "$2" ]]; then usage; exit 1; fi
            REDO_STEPS+=("$2"); shift 2;;
        -h|--help) usage; exit 0;;
        *) echo -e "${ERROR}Unknown option: $1"; usage; exit 1;;
    esac
done

#------------------------------------------#
#   Make sure we are running in the repo   #
#------------------------------------------#

# Hyprland's lua symlinks, my-install and this script all assume the repo is
# at ~/nixos-config, and nix flakes only see files inside the git repo.
REPO_DIR="$HOME/nixos-config"
SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"

if [[ "$SCRIPT_DIR" != "$REPO_DIR" ]]; then
    echo -e "${ERROR}This repo has to live in ${REPO_DIR}, but this script is in ${SCRIPT_DIR}"
    echo -e "${INFO}Move it (mv \"${SCRIPT_DIR}\" \"${REPO_DIR}\") and run the script again"
    exit 1
fi

cd "$REPO_DIR"

#---------------------------------------------#
#   Check the required tools are installed    #
#---------------------------------------------#

# One nix-shell for everything, then the script re-runs itself inside it. The
# guard variable stops an endless re-run if a tool is still missing afterwards.
missing=()
for tool in whiptail efibootmgr nh git perl; do
    if ! command -v "$tool" &> /dev/null; then
        missing+=("$tool")
    fi
done

if (( ${#missing[@]} > 0 )); then
    if [[ -n "$INSTALL_SH_BOOTSTRAPPED" ]]; then
        echo -e "${ERROR}Still missing after nix-shell: ${missing[*]}"
        exit 1
    fi
    echo -e "${INFO}Missing ${missing[*]}, downloading required packages"
    INSTALL_SH_BOOTSTRAPPED=1 nix-shell -p newt efibootmgr nh git perl --run "$(printf '%q ' "$(realpath "$0")" "${ORIG_ARGS[@]}")"
    exit $?
fi

#----------------------------------#
#   Check we booted in UEFI mode   #
#----------------------------------#

# modules/core/bootloader.nix uses grub with efiSupport + canTouchEfiVariables,
# which cannot install on a legacy BIOS boot.
if [ ! -d /sys/firmware/efi ]; then
    echo -e "${ERROR}This machine did not boot in UEFI mode, the bootloader config needs it"
    exit 1
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

#--------------------------------------#
#   Saved answers and progress state   #
#--------------------------------------#

# Every answer and every finished step is saved outside the repo (so git add .
# never picks it up). After a failed build, fix the config and run the script
# again: it reuses the answers and skips the steps that already finished.
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nixos-config-install"
ANSWERS_FILE="$STATE_DIR/answers.env"
BUILD_LOG="$STATE_DIR/build.log"
STEPS=(config_edit host_files build sleep finished)

if $RESET_STATE; then
    rm -rf "$STATE_DIR"
    echo -e "${INFO}Forgot saved answers and progress (edits already made to the repo are kept)"
fi
mkdir -p "$STATE_DIR"

step_done() { [ -e "$STATE_DIR/done.$1" ]; }
mark_done() { touch "$STATE_DIR/done.$1"; }

for step in "${REDO_STEPS[@]}"; do
    if [[ " ${STEPS[*]} " != *" $step "* ]]; then
        echo -e "${ERROR}Unknown step '$step', the steps are: ${STEPS[*]}"
        exit 1
    fi
    rm -f "$STATE_DIR/done.$step"
    # Everything after the redone step has to run again too, so the install
    # is no longer "finished" (otherwise the script exits before doing anything)
    rm -f "$STATE_DIR/done.finished"
done

if step_done finished; then
    echo -e "${OK}This install already finished. Use --reset to start over or --redo STEP to repeat a step."
    exit 0
fi

print_summary() {
    cat << ENDOFSUMMARY
Username:    $username
Host:        $HOST
Git Name:    $gitname
Git Email:   $gitemail
GitHub user: $githubUser
New host:    $isNewHost
Laptop:      $isLaptop
Nvidia:      $hasNvidia
High Power:  $isHighPower
Server:      $isServer
Dual Boot:   $isDualBoot
Wake-on-LAN: ${wolInterface:-off}
ENDOFSUMMARY
}

save_answers() {
    for var in username HOST isNewHost swapSize isLaptop hasNvidia isHighPower isServer isDualBoot dualBootId gitname gitemail githubUser wolInterface; do
        printf '%s=%q\n' "$var" "${!var}"
    done > "$ANSWERS_FILE"
}

# A fresh install has no swap until the first successful switch creates it, and
# evaluating + building this config can need far more RAM than a small machine
# has, so the kernel's OOM killer ends the build. Top RAM+swap up to ~32GB with a
# temporary swapfile for the install (removed again when the install finishes).
INSTALL_SWAP=/nixos-install.swap

temp_swap_active() {
    swapon --show=NAME --noheadings 2> /dev/null | grep -qx "$INSTALL_SWAP"
}

ensure_temp_swap() {
    temp_swap_active && return 0

    local ram_kb swap_kb total_gb want_gb free_gb rootFs
    ram_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    swap_kb=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo)
    total_gb=$(( (ram_kb + swap_kb) / 1024 / 1024 ))
    if (( total_gb >= 32 )); then
        return 0
    fi

    want_gb=$(( 32 - total_gb ))
    if (( want_gb < 8 )); then
        want_gb=8
    fi

    free_gb=$(df -BG --output=avail / | tail -n 1 | tr -dc '0-9')
    if (( free_gb < want_gb + 10 )); then
        echo -e "${WARN}Only ${free_gb}GB free, not enough for a ${want_gb}GB temporary swapfile. The build may run out of memory."
        return 0
    fi

    echo -e "${INFO}Only $(( ram_kb / 1024 / 1024 ))GB RAM: adding a ${want_gb}GB temporary swapfile (${INSTALL_SWAP}) so the build is not killed for lack of memory"
    if [ ! -f "$INSTALL_SWAP" ]; then
        rootFs=$(findmnt -no FSTYPE / | head -n 1)
        if [ "$rootFs" = "btrfs" ]; then
            sudo btrfs filesystem mkswapfile --size "${want_gb}G" "$INSTALL_SWAP" || true
        else
            sudo fallocate -l "${want_gb}G" "$INSTALL_SWAP" \
                && sudo chmod 600 "$INSTALL_SWAP" \
                && sudo mkswap "$INSTALL_SWAP" > /dev/null || true
        fi
    fi
    sudo swapon "$INSTALL_SWAP" || echo -e "${WARN}Could not enable the temporary swapfile, the build may run out of memory"
}

remove_temp_swap() {
    if temp_swap_active; then
        sudo swapoff "$INSTALL_SWAP" || true
    fi
    sudo rm -f "$INSTALL_SWAP"
}

# Fewer parallel jobs/cores on machines with little RAM (extra args for nix)
build_limits() {
    local ram_gb cores
    ram_gb=$(( $(awk '/^MemTotal:/ {print $2}' /proc/meminfo) / 1024 / 1024 ))
    if (( ram_gb >= 32 )); then
        return 0
    fi
    cores=$(( ram_gb / 2 ))
    if (( cores < 1 )); then
        cores=1
    fi
    if (( cores > $(nproc) )); then
        cores=$(nproc)
    fi
    echo "--max-jobs 1 --cores $cores"
}

# Runs the build, keeping a copy of the output (a bare TTY scrolls it away).
# Returns nh's exit code, not tee's.
run_nh() {
    ensure_temp_swap
    local limits
    limits=$(build_limits)

    # Flakes only see files git knows about, so new files must be added first
    git add .
    echo "=== $(date) ===" >> "$BUILD_LOG"
    NIX_CONFIG="experimental-features = nix-command flakes" nh os switch "$REPO_DIR" -H "${HOST}" ${limits:+-- $limits} 2>&1 | tee -a "$BUILD_LOG"
    local rc=${PIPESTATUS[0]}
    return $rc
}

build_failed() {
    echo
    echo -e "${ERROR}The build failed. Your answers and progress are saved, nothing needs re-entering."
    echo -e "${INFO}Last lines of the log (all of it: less ${BUILD_LOG}):"
    tail -n 25 "$BUILD_LOG"
    echo

    # "Target profile path does not exist" means nix never produced a result,
    # which is what you get when the build process is killed for lack of memory
    if grep -q "Target profile path does not exist" "$BUILD_LOG" \
        || sudo -n journalctl -k -b --no-pager 2> /dev/null | grep -qi "out of memory\|oom-kill"; then
        echo -e "${WARN}That looks like the build being killed for lack of memory, not a config error."
        echo -e "${INFO}Check with: sudo journalctl -k -b | grep -i oom"
        echo -e "${INFO}The next run adds a temporary swapfile and limits parallel jobs; if it still happens, close other programs or add RAM."
        echo
    fi
    echo -e "${INFO}Fix the problem in ${REPO_DIR} with an editor (e.g. nano ${REPO_DIR}/hosts/${HOST}/default.nix),"
    echo -e "${INFO}then run ${GREEN}./install.sh${RESET} again. It carries on from the failed build."
    exit 1
}

ask_questions() {

#------------------#
#   Get username   #
#------------------#

while true; do
    username=$(whiptail --inputbox "Enter your username (must be the account you are logged in as):" 9 40 "$USER" --title "Username" 3>&1 1>&2 2>&3)

    if [ $? != 0 ]; then
        exit 1
    fi

    if ! [[ $username =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
        whiptail --msgbox "Invalid username: '$username'" 8 40 --title Error 3>&1 1>&2 2>&3
        continue
    fi

    if [ "$username" != "$USER" ]; then
        whiptail --msgbox "You are logged in as '$USER' but entered '$username'. NixOS would create '$username' as a brand new account with no password, so you could not log in as it." 11 60 --title Warning
    fi

    if (whiptail --yesno "Use '$username' as username?" 8 40 --title "Confirm Username"); then
        break
    fi
done

#-----------------#
#   Choose host   #
#-----------------#

hostArgs=()
for dir in hosts/*/; do
    name=$(basename "$dir")
    if [ "$name" != "template" ]; then
        hostArgs+=("$name" "$name configuration" OFF)
    fi
done
hostCount=$(( ${#hostArgs[@]} / 3 + 1 ))

while true; do
    HOST=$(whiptail --radiolist "Choose a host:" $(( hostCount + 8 )) 48 $hostCount \
        "new" "New configuration" ON \
        "${hostArgs[@]}" \
        --title "Host" 3>&1 1>&2 2>&3)

    if [ $? != 0 ]; then
        exit 1
    fi

    if (whiptail --yesno "Use the '$HOST' host?" 8 40 --title "Confirm Host"); then
        break
    fi
done

newHost=""
isNewHost=false
if [ "$HOST" = "new" ]; then
    isNewHost=true
    while true; do
        newHost=$(whiptail --inputbox "Enter your new host name (lowercase letters, numbers and -, cannot be an existing one):" 9 50 --title "Host Name" 3>&1 1>&2 2>&3)

        if [ $? != 0 ]; then
            exit 1
        fi

        if ! [[ $newHost =~ ^[a-z][a-z0-9-]{0,62}$ ]] || [ -e "hosts/${newHost}" ]; then
            whiptail --msgbox "'$newHost' is not a valid host name, or hosts/$newHost already exists (left over from an earlier run? remove hosts/$newHost and undo the flake.nix change first)" 11 60 --title Error
            continue
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

        if ! [[ $swapSize =~ ^[1-9][0-9]*$ ]]; then
            whiptail --msgbox "Swap size must be a whole number of GB" 8 40 --title Error
            continue
        fi

        if (whiptail --yesno "Use '$swapSize' as new host swap size (GB)?" 8 40 --title "Confirm Swap Size"); then
            break
        fi
    done
fi

#---------------------------#
#   Hardware configuration  #
#---------------------------#

# Reads a my.<option> = true/false flag out of hosts/<host>/default.nix
read_host_flag() {
    local value
    value=$(sed -n "s/^[[:space:]]*my\.$1[[:space:]]*=[[:space:]]*\(true\|false\);.*/\1/p" "hosts/${HOST}/default.nix" | head -n 1)
    echo "${value:-false}"
}

wolInterface=""

if $isNewHost; then
    if (whiptail --yesno "Is this machine a laptop?" 8 40 --title "Hardware: Laptop"); then
        isLaptop=true
    else
        isLaptop=false
    fi

    if (whiptail --yesno "Does this machine have an Nvidia GPU?" 8 40 --title "Hardware: Nvidia"); then
        hasNvidia=true
    else
        hasNvidia=false
    fi

    if (whiptail --yesno "Is this a high-power machine? (desktop/powerful laptop/server, gets every package)" 9 50 --title "Hardware: Power"); then
        isHighPower=true
    else
        isHighPower=false
    fi

    if (whiptail --yesno "Is this an always-on server? (never auto-suspends, no desktop apps auto-launched)" 9 50 --title "Hardware: Server"); then
        isServer=true
    else
        isServer=false
    fi

    if (whiptail --yesno "Is this machine using dual boot?" 8 40 --title "Hardware: Boot"); then
        isDualBoot=true
    else
        isDualBoot=false
    fi

    # Wake-on-LAN needs the real (wired) interface name, so offer the default route's one
    if $isHighPower; then
        nic=$(ip -o route show default 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "dev") { print $(i + 1); exit }}')
        if [ -n "$nic" ] && [ ! -d "/sys/class/net/$nic/wireless" ]; then
            if (whiptail --yesno "Enable Wake-on-LAN on '$nic'? (you will still need to enable it in the BIOS)" 9 50 --title "Hardware: Wake-on-LAN"); then
                wolInterface=$nic
            fi
        fi
    fi
else
    isLaptop=$(read_host_flag isLaptop)
    hasNvidia=$(read_host_flag hasNvidia)
    isHighPower=$(read_host_flag isHighPower)
    isServer=$(read_host_flag isServer)
    isDualBoot=$(read_host_flag isDualBoot)
fi

if $isDualBoot; then
    while true; do
        bootCode=$(whiptail --inputbox "$(efibootmgr)\n\nEnter the 4 digit boot code (BootXXXX <-- these 4 numbers) of your other OS:" 25 130 --title "Code" 3>&1 1>&2 2>&3)

        if [ $? != 0 ]; then
            exit 1
        fi

        if ! [[ $bootCode =~ ^[0-9A-Fa-f]{4}$ ]]; then
            whiptail --msgbox "The boot code must be exactly 4 hex digits, e.g. 0004" 8 40 --title Error
            continue
        fi

        if (whiptail --yesno "Use '$bootCode' as boot code? (will only break a shell alias)" 8 40 --title "Confirm Code"); then
            dualBootId=$bootCode
            break
        fi
    done
fi

#---------------------------#
#     Enter git details     #
#---------------------------#

while true; do
    gitname=$(whiptail --inputbox "Enter your git username/name:" 9 40 "${gitname:-$DEFAULT_GIT_NAME}" --title "Name" 3>&1 1>&2 2>&3)

    if [ $? != 0 ]; then
        exit 1
    fi

    if (whiptail --yesno "Use '$gitname' as git name? (shows up in commits)" 8 40 --title "Confirm Name"); then
        break
    fi
done

while true; do
    gitemail=$(whiptail --inputbox "Enter your git email:" 9 40 "${gitemail:-$DEFAULT_GIT_EMAIL}" --title "Email" 3>&1 1>&2 2>&3)

    if [ $? != 0 ]; then
        exit 1
    fi

    if (whiptail --yesno "Use '$gitemail' as email? (shows up in commits)" 8 40 --title "Confirm Email"); then
        break
    fi
done

# The git name is not necessarily the GitHub username (it can contain spaces)
githubUser=$gitname
if [[ $gitname =~ [[:space:]] ]]; then
    while true; do
        githubUser=$(whiptail --inputbox "Your git name has a space in it. Enter your GitHub username (used for the repo's remote URL):" 10 50 --title "GitHub" 3>&1 1>&2 2>&3)

        if [ $? != 0 ]; then
            exit 1
        fi

        if [[ $githubUser =~ ^[A-Za-z0-9-]+$ ]]; then
            break
        fi
        whiptail --msgbox "'$githubUser' is not a valid GitHub username" 8 40 --title Error
    done
fi

#---------------------------#
#   Recap of user choices   #
#---------------------------#

SUMMARY=$(print_summary)

whiptail --msgbox "$SUMMARY" 23 40 --title "Installation Summary"

#-----------------------#
#   Last Confirmation   #
#-----------------------#

if ! (whiptail --yesno "You are about to build the system for host '$HOST'. Proceed?" 9 40 --title "Final Confirmation"); then
    exit 0
fi

save_answers
}

resumed=false
if [ -f "$ANSWERS_FILE" ]; then
    . "$ANSWERS_FILE"
    resumed=true
    echo -e "${INFO}Resuming an earlier run with the answers you already gave (./install.sh --reset to start over):"
    print_summary
    for step in "${STEPS[@]}"; do
        if step_done "$step"; then
            echo -e "${OK}${step}: done"
        else
            echo -e "${INFO}${step}: still to do"
        fi
    done
    echo
else
    ask_questions
fi

#---------------------#
#    Change names     #
#---------------------#

if ! step_done config_edit; then

echo -e "${INFO}Changing username to ${GREEN}$username${RESET}"
sed -i "s/${CURRENT_USERNAME}/${username}/g" flake.nix

if $isNewHost && ! grep -q "\./hosts/${HOST}\$" flake.nix; then
    echo -e "${INFO}Adding host ${GREEN}${HOST}${RESET} to flake.nix"

    hostBlock=$(mktemp)
    cat > "$hostBlock" << ENDOFNIX
      ${HOST} = nixpkgs-stable.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/${HOST}
          inputs.grub2-themes.nixosModules.default
          inputs.stylix.nixosModules.stylix
          inputs.nix-index-database.nixosModules.default
          inputs.nur.modules.nixos.default
          inputs.chaotic.nixosModules.default
        ];
        specialArgs = {
          host = "${HOST}";
          inherit self inputs username pkgs-stable pkgs-unstable;
        };
      };
ENDOFNIX

    # nixosConfigurations is closed by the last "    };" line, which is followed by "  };"
    closeLine=$(grep -n '^    };$' flake.nix | tail -n 1 | cut -d: -f1)
    if [ -z "$closeLine" ] || [ "$(sed -n "$((closeLine + 1))p" flake.nix)" != "  };" ]; then
        echo -e "${ERROR}Could not find where nixosConfigurations ends in flake.nix, add the ${HOST} host to it by hand"
        rm -f "$hostBlock"
        exit 1
    fi
    sed -i "$((closeLine - 1))r $hostBlock" flake.nix
    rm -f "$hostBlock"
fi

#----------------------#
#   Clear git config   #
#----------------------#

echo -e "${INFO}Changing git account details"
sed -i "s/\"sonicpanther101\"/\"${gitname}\"/g" modules/home/git.nix
sed -i "s/\"sonicpanther101@gmail.com\"/\"${gitemail}\"/g" modules/home/git.nix

mark_done config_edit
fi

hwConfig="hosts/${HOST}/hardware-configuration.nix"

# Puts a swapfile in the host's hardware config (NixOS creates the file itself
# on the next switch). Succeeds if the config ends up with a /swapfile.
add_swapfile_config() {
    if ! grep -q '"/swapfile"' "$hwConfig"; then
        SWAP_BLOCK="swapDevices = [{
    device = \"/swapfile\";
    size = ${swapSize} * 1024; # ${swapSize}GB
  }];" perl -0777 -pi -e 's/swapDevices\s*=\s*\[\s*\]\s*;/$ENV{SWAP_BLOCK}/' "$hwConfig"
    fi
    grep -q '"/swapfile"' "$hwConfig"
}

# Adds the hibernate/resume settings to the hardware config and rebuilds. Safe
# to run again: it replaces any resume settings an earlier run added. Returns
# non-zero (without marking the step done) whenever something did not work.
setup_sleep() {
    echo -e "${INFO}Finishing setting up sleep"

    if ! add_swapfile_config; then
        echo -e "${ERROR}Could not add a swapfile to ${hwConfig}: there is no empty 'swapDevices = [ ];' to replace (does it already have other swap devices?)"
        return 1
    fi

    # NixOS only creates the swapfile when it switches to a config that has it,
    # so if it is not there yet (swap was never added, or the build was skipped) build once first
    if ! sudo test -f /swapfile; then
        echo -e "${INFO}/swapfile does not exist yet, building so NixOS creates it..."
        if ! run_nh; then
            build_failed
        fi
    fi

    local physicalOffset uuid swapFs kernelParams
    physicalOffset=$(sudo filefrag -v /swapfile | awk '$1 == "0:" { sub(/\.\..*/, "", $4); print $4; exit }')
    uuid=$(findmnt -no UUID -T /swapfile | head -n 1)
    swapFs=$(findmnt -no FSTYPE -T /swapfile | head -n 1)

    if [ "$swapFs" != "ext4" ] || [ -z "$physicalOffset" ] || [ -z "$uuid" ]; then
        echo -e "${ERROR}Could not work out the resume offset/device (swap filesystem: '${swapFs}', offset: '${physicalOffset}', uuid: '${uuid}'). Only ext4 swapfiles are supported"
        return 1
    fi

    kernelParams="\"resume_offset=${physicalOffset}\""

    # Only force deep sleep if the machine supports it (some only offer s2idle)
    if grep -q deep /sys/power/mem_sleep; then
        kernelParams="\"mem_sleep_default=deep\" ${kernelParams}"
    fi

    # Remove resume settings from an earlier run so a redo never keeps stale values
    perl -0777 -pi -e 's/\n\n  boot\.kernelParams = \[[^\n]*resume_offset[^\n]*\];\n\n  boot\.resumeDevice = [^\n]*;//' "$hwConfig"
    sed -i -e '/boot\.kernelParams.*resume_offset/d' -e '/^[[:space:]]*boot\.resumeDevice/d' "$hwConfig"

    RESUME_BLOCK="
  boot.kernelParams = [ ${kernelParams} ];

  boot.resumeDevice = \"/dev/disk/by-uuid/${uuid}\";" \
        perl -0777 -pi -e 's/\}\s*\z/$ENV{RESUME_BLOCK}\n}\n/' "$hwConfig"

    if ! grep -q "resume_offset=${physicalOffset}" "$hwConfig" || ! grep -q 'boot.resumeDevice' "$hwConfig"; then
        echo -e "${ERROR}Could not add the resume settings to ${hwConfig} (it no longer ends with a closing brace?). Add boot.resumeDevice = \"/dev/disk/by-uuid/${uuid}\" and resume_offset=${physicalOffset} by hand"
        return 1
    fi
    echo -e "${OK}Added resume settings to ${hwConfig}"

    echo -e "${INFO}Starting second system build to enable sleep... this one should be quicker."
    if ! run_nh; then
        build_failed
    fi
    mark_done sleep
}

if ! step_done host_files; then

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
if [ -d ~/Pictures/wallpapers ]; then
    echo -e "${INFO}Wallpapers already present, skipping"
else
    git clone https://github.com/sonicpanther101/wallpapers ~/Pictures/wallpapers \
        || echo -e "${WARN}Could not clone the wallpapers, continuing without them"
fi

## Create the host if it is a new one
mkdir -p "hosts/${HOST}"

if $isNewHost; then
    cat > "hosts/${HOST}/default.nix" << ENDOFNIX
{ ... }: {
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];
  my.isLaptop    = ${isLaptop};
  my.hasNvidia   = ${hasNvidia};
  my.isHighPower = ${isHighPower};
  my.isDualBoot  = ${isDualBoot};
  my.isServer    = ${isServer};
}
ENDOFNIX

    if [ -n "$wolInterface" ]; then
        sed -i "s|^  my.isServer .*|&\n  my.wakeOnLanInterface = \"${wolInterface}\";|" "hosts/${HOST}/default.nix"
    fi
fi

## Get the hardware configuration
if [ -f /etc/nixos/hardware-configuration.nix ]; then
    echo -e "${INFO}Copying ${MAGENTA}/etc/nixos/hardware-configuration.nix${RESET} to ${MAGENTA}./${hwConfig}${RESET}"
    if ! $isNewHost; then
        echo -e "${WARN}This replaces the repo's ${hwConfig}; extra drives/swap settings from the old one are still in git history"
    fi
    cp /etc/nixos/hardware-configuration.nix "$hwConfig"
else
    echo -e "${WARN}${MAGENTA}/etc/nixos/hardware-configuration.nix${RESET} not found, generating one"
    sudo nixos-generate-config --show-hardware-config > "$hwConfig"
fi

## Create swap file for sleeping
if $isNewHost; then
    echo -e "${INFO}Setting up swap for new host ${MAGENTA}${HOST}${RESET}"
    if ! add_swapfile_config; then
        echo -e "${WARN}Could not add a swapfile to ${hwConfig} (it already has swap devices?). Sleep is set up at the end; if that fails, fix it and run ./install.sh --redo sleep"
    fi
fi

## Change boot ID for dualboot alias
if $isDualBoot; then
    sed -i "s|dualBootId = \"[0-9A-Fa-f]*\";|dualBootId = \"${dualBootId}\";|" modules/home/terminal/zsh.nix
fi

mark_done host_files
fi

#------------------#
#   Installation   #
#------------------#

if ! step_done build; then
    echo -e "${INFO}Starting system build... this may take a while."
    if ! run_nh; then
        build_failed
    fi
    mark_done build
    echo -e "${INFO}System build finished successfully"
fi

# Servers never sleep, so they skip hibernate setup
sleepFailed=false
if $isNewHost && ! $isServer; then
    if ! step_done sleep && ! setup_sleep; then
        sleepFailed=true
    fi
elif [[ " ${REDO_STEPS[*]} " == *" sleep "* ]]; then
    echo -e "${INFO}Sleep is only set up for new hosts that are not servers, so there is nothing to redo"
fi

echo -e "${INFO}Setting up my-install script"
git remote set-url origin "git@github.com:${githubUser}/nixos-config.git"
mkdir -p ~/.ssh
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "${gitemail}" -f ~/.ssh/id_ed25519
fi
key=$(cut -d' ' -f1,2 ~/.ssh/id_ed25519.pub)
echo -e "${INFO}Copy this key:\n${key}\nThen add the public key to GitHub: Account Settings → SSH and GPG keys → New SSH key"

remove_temp_swap
mark_done finished

if $sleepFailed; then
    echo -e "${ERROR}Sleep is ${RED}NOT${RESET} set up (see the error above). Fix the problem, then run ${GREEN}./install.sh --redo sleep${RESET}"
fi
echo -e "${INFO}You can now reboot to apply the config"
echo -e "${INFO}After you reboot, make sure to set up any specialised hardware by looking in the ./modules/core/hardware.nix and changing some of the host checking stakements throughout the config"
