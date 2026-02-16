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
    ./../../packages
    ./gaming.nix
    ./wayland.nix
    ./printing.nix
  ];
  # ++ (if someCondition then [ ./optional.nix ] else []);
}
