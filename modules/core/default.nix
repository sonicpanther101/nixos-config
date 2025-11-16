{ host, ... } : {
  imports = [
    ./audio.nix
    ./bootloader.nix
    ./network.nix
    ./services.nix
    ./system.nix
    ./user.nix
    ./hardware.nix
  ];
  # ++ (if someCondition then [ ./optional.nix ] else []);
}
