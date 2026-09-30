#!/usr/bin/env bash
# Build and run a QEMU VM of this host's NixOS config (see modules/core/vm.nix).
# Only installed on high-power hosts.

Help()
{
   echo
   echo "Syntax: my-vm [-r|b|t|h]"
   echo "options:"
   echo "r     Reset: delete the VM's disk image first (fresh state)"
   echo "b     Only build the VM, don't start it"
   echo "t     Show error trace"
   echo "h     Print this Help"
}

reset=false
build_only=false
extra_args=()

while getopts "rbth" option; do
    case $option in
        r) reset=true;;
        b) build_only=true;;
        t) extra_args+=(--show-trace);;
        h) Help; exit;;
        \?) echo "Error: Invalid option"; exit 1;;
    esac
done

set -e

host=$(hostname)
host=${host%-vm} # so it also works if run from inside the VM
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nixos-vm"
mkdir -p "$state_dir"
cd "$state_dir"

if [[ $reset == true ]]; then
    echo "Deleting VM disk image(s)..."
    rm -f ./*.qcow2
fi

echo "Building VM for ${host}..."
nixos-rebuild build-vm --flake "$HOME/nixos-config#${host}" "${extra_args[@]}"

if [[ $build_only == true ]]; then
    echo "Built: $state_dir/result/bin/"
    exit 0
fi

# Disk image ($state_dir/<hostname>-vm.qcow2) is created on first run and kept between runs.
exec ./result/bin/run-*-vm
