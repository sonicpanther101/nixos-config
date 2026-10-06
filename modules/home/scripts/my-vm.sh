#!/usr/bin/env bash
# Build and run a QEMU VM of this host's NixOS config (see modules/core/vm.nix).
# Only installed on high-power hosts.
#
# With -t/-f it becomes an AI sandbox: goose CLI works on the goal INSIDE the VM
# (on a throw-away copy of the config) and hands back a diff + report. The real
# system and the real git repo are only ever read, never written.

Help()
{
   echo
   echo "Syntax: my-vm [-r|b|T|h] [-t goal | -f file] [-m model] [-n turns] [-H] [-k]"
   echo "options:"
   echo "r     Reset: delete the VM's disk image first (fresh state)"
   echo "b     Only build the VM, don't start it"
   echo "T     Show error trace"
   echo "h     Print this Help"
   echo
   echo "AI sandbox:"
   echo "t     Goal/problem for goose to solve, e.g. -t \"waybar clock shows UTC, fix it\""
   echo "f     Same, but read the goal from a file"
   echo "m     Ollama model for goose (default: qwen3.6:35b-a3b-mtp-q4_K_M)"
   echo "n     Max agent turns (default: 150)"
   echo "H     Headless: no VM window, just stream goose's log here"
   echo "k     Keep the VM running afterwards (default: it powers off when done)"
}

reset=false
build_only=false
headless=false
keep=false
task=""
task_file=""
model=""
turns=""
extra_args=()

while getopts "rbThHkt:f:m:n:" option; do
    case $option in
        r) reset=true;;
        b) build_only=true;;
        T) extra_args+=(--show-trace);;
        t) task="$OPTARG";;
        f) task_file="$OPTARG";;
        m) model="$OPTARG";;
        n) turns="$OPTARG";;
        H) headless=true;;
        k) keep=true;;
        h) Help; exit;;
        \?) echo "Error: Invalid option"; exit 1;;
    esac
done

set -e

repo="$HOME/nixos-config"
host=$(hostname)
host=${host%-vm} # so it also works if run from inside the VM
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nixos-vm"
mkdir -p "$state_dir"
cd "$state_dir"

if [[ -n "$task_file" ]]; then
    [[ -f "$task_file" ]] || { echo "No such file: $task_file"; exit 1; }
    task=$(cat "$task_file")
fi

if [[ $reset == true ]]; then
    echo "Deleting VM disk image(s)..."
    rm -f ./*.qcow2
fi

echo "Building VM for ${host}..."
nixos-rebuild build-vm --flake "$repo#${host}" "${extra_args[@]}"

if [[ $build_only == true ]]; then
    echo "Built: $state_dir/result/bin/"
    exit 0
fi

tail_pid=""
share=""
if [[ -n "$task" ]]; then
    if ! curl -sf -m 3 http://127.0.0.1:11434/api/tags > /dev/null; then
        echo "Warning: ollama isn't answering on 127.0.0.1:11434 — goose won't have a model to talk to."
    fi

    share="$state_dir/share"
    rm -rf "$share"
    mkdir -p "$share/config" "$share/out"

    # Snapshot of the config (tracked + untracked-but-not-ignored, no .git).
    # Read-only on the real repo; the VM only ever sees this copy.
    ( cd "$repo" && git ls-files -z --cached --others --exclude-standard \
        | while IFS= read -r -d '' f; do [[ -e "$f" ]] && printf '%s\0' "$f"; done \
        | tar --null -T - -cf - ) | tar -xf - -C "$share/config"

    printf '%s\n' "$task" > "$share/task.md"
    {
        [[ -n "$model" ]] && echo "GOOSE_MODEL=$model"
        [[ -n "$turns" ]] && echo "MAX_TURNS=$turns"
    } > "$share/task.env"
    [[ $keep == true ]] && touch "$share/keep"
    touch "$share/out/goose.log"

    export SHARED_DIR="$share"
    if [[ $headless == true ]]; then
        export MY_VM_DISPLAY=none MY_VM_GPU="-device virtio-vga"
    fi

    echo "Goal: $task"
    echo "Streaming goose's log (VM will power off when done)..."
    tail -n +1 -f "$share/out/goose.log" &
    tail_pid=$!
fi

# Disk image ($state_dir/<hostname>-vm.qcow2) is created on first run and kept between runs.
set +e
./result/bin/run-*-vm
vm_rc=$?
set -e

if [[ -n "$tail_pid" ]]; then
    kill "$tail_pid" 2> /dev/null || true
    dest="$state_dir/runs/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$dest"
    cp -r "$share/out/." "$dest/"
    echo
    echo "════════════════ REPORT ════════════════"
    cat "$dest/report.md" 2> /dev/null || echo "(no report — see $dest/goose.log)"
    echo "════════════════════════════════════════"
    echo
    [[ -s "$dest/changes.stat" ]] && cat "$dest/changes.stat"
    echo
    echo "Saved in: $dest   (report.md, changes.md, changes.diff, goose.log)"
    if [[ -s "$dest/changes.diff" ]]; then
        echo "Review the diff, then to apply it to your real config:"
        echo "  cd ~/nixos-config && git apply --check $dest/changes.diff && git apply $dest/changes.diff"
    fi
fi
exit $vm_rc
