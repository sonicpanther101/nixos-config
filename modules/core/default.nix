{ host, ... } : {
  imports = [
    ./audio.nix
    ./bootloader.nix
    ./network.nix
    ./services.nix
    ./style.nix
    ./system.nix
    ./security.nix
    ./user.nix
    ./hardware.nix
    ./gaming.nix
    ./wayland.nix
    ./printing.nix
    
    # ─── Remote builds ───────────────────────────────────────────────────────
    # To make a machine act as a BUILD SERVER:
    #   1. Follow the steps in build-machine.nix
    #   2. Uncomment the line for that host below
    #
    # To make a machine OFFLOAD builds to the server:
    #   1. Follow the steps in weak-machine.nix
    #   2. Uncomment the line for that host below
    # ─────────────────────────────────────────────────────────────────────────
  ] ++ (if (host == "desktop") then [
    # ./build-machine.nix   # ← uncomment to make desktop the build server
  ] else if (host == "laptop-2") then [
    # ./weak-machine.nix    # ← uncomment to offload laptop-2 builds to desktop
  ] else if (host == "laptop") then [
    # ./weak-machine.nix    # ← uncomment to offload laptop builds to desktop
  ] else []);
}