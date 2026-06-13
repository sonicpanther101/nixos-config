{ host, config, ... } : {
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
    ./virtualisation.nix
    
    # ─── Remote builds ───────────────────────────────────────────────────────
    # To make a machine act as a BUILD SERVER:
    #   1. Follow the steps in build-machine.nix
    #
    # To make a machine OFFLOAD builds to the server:
    #   1. Follow the steps in weak-machine.nix
    #   3. Comment out the imports above if it is first build for a laptop
    # ─────────────────────────────────────────────────────────────────────────
    # Uncomment to enable
    ./build-machine.nix
    ./weak-machine.nix
  ];
}