cd ~/nixos-config

if [ "$1" = "list" ]; then
  nix flake metadata 2>/dev/null | grep -E '^├───|^└───' | sed 's/[├└]───//' | cut -d: -f1 # Print all flake inputs
elif [ "$#" -eq 0 ]; then
  nix flake update # No inputs specified: update everything
else
  # Work out every "X.follows = Y" relationship declared in flake.nix, e.g.
  #   walker = { ...; inputs.nixpkgs.follows = "nixpkgs-stable"; ... };
  # so that when an input is updated, anything pinned to follow it gets
  # updated in the same pass. This avoids inputs like home-manager/stylix
  # silently drifting behind nixpkgs-unstable (which causes version
  # mismatch warnings even though they technically "follow" it).
  pairs=$(awk '
    /^[[:space:]]*[a-zA-Z0-9_-]+[[:space:]]*=[[:space:]]*\{/ {
      match($0, /[a-zA-Z0-9_-]+/); current = substr($0, RSTART, RLENGTH)
    }
    /\.follows[[:space:]]*=[[:space:]]*"/ {
      match($0, /"[^"]+"/); target = substr($0, RSTART+1, RLENGTH-2)
      if (current != "") print current":"target
    }
  ' flake.nix)

  inputs="$*"
  changed=1
  while [ "$changed" = 1 ]; do
    changed=0
    for pair in $pairs; do
      src=${pair%%:*}
      tgt=${pair##*:}
      case " $inputs " in
        *" $tgt "*)
          case " $inputs " in
            *" $src "*) ;; # already included
            *) inputs="$inputs $src"; changed=1 ;;
          esac
          ;;
      esac
    done
  done

  echo "Updating: $inputs"
  nix flake update $inputs # Update specified inputs plus anything that follows them
fi
