{ host, ...}:{
  imports = [
    ./bootloader.nix
    ./network.nix
    ./services.nix
  ];
  # ++ (if someCondition then [ ./optional.nix ] else []);
}