#!/usr/bin/env bash
# Build the VM's own system from the sandbox flake and activate it live.
#
# NOT `nixos-rebuild switch .#<host>`: that would build the plain host system
# (real disks, nvidia, ...) rather than the VM variant we're actually running.
set -uo pipefail
export PATH=/run/wrappers/bin:/run/current-system/sw/bin:$PATH

sandbox="${SANDBOX:-$HOME/nixos-config}"
host=$(hostname); host=${host%-vm}
log=$(mktemp)

cd "$sandbox" || { echo "vm-rebuild: $sandbox not found"; exit 1; }

# Flakes only see git-tracked files, so stage everything (new files included).
git add -A

echo ">> building ${host} (VM variant)..."
if ! out=$(nix build --no-link --print-out-paths -L \
      ".#nixosConfigurations.${host}.config.virtualisation.vmVariant.system.build.toplevel" \
      2> "$log"); then
    echo "!! BUILD FAILED (last 80 lines):"
    tail -n 80 "$log"
    exit 1
fi

echo ">> activating $out"
if ! sudo "$out/bin/switch-to-configuration" test > "$log" 2>&1; then
    echo "!! ACTIVATION FAILED (last 60 lines):"
    tail -n 60 "$log"
    exit 2
fi
tail -n 20 "$log"

echo ">> OK: VM is now running your current ~/nixos-config."
failed=$(systemctl --failed --no-legend --plain 2>/dev/null)
if [ -n "$failed" ]; then
    echo ">> note: failed units right now (some may be unrelated VM noise):"
    echo "$failed"
fi
