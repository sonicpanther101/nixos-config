cd ~/nixos-config

if [ "$1" = "list" ]; then
  nix flake metadata 2>/dev/null | grep -E '^├───|^└───' | sed 's/[├└]───//' | cut -d: -f1 # Print all flake inputs
else
  nix flake update "$@" # Update specified inputs
fi