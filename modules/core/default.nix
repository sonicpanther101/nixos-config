{ ... } : {
# { host, ... } : {
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
  ];
  # ++ (if (host == "desktop") then [ 
  #   ./build-machine.nix
  # ] else [
  #   ./weak-machine.nix
  # ]);
}