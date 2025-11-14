{ host, ... } : {
  imports = [
    ./bootloader.nix
    ./network.nix
    ./services.nix
    ./system.nix
    ./user.nix
  ];
  # ++ (if someCondition then [ ./optional.nix ] else []);
}