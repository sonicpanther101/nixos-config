{ host, ... } : {
  imports = [
    ./audio.nix
    ./bootloader.nix
    ./network.nix
    ./services.nix
    ./style.nix
    ./system.nix
    ./user.nix
    ./hardware.nix
    # ./foobar2000-mpris.nix
  ];
  # ++ (if someCondition then [ ./optional.nix ] else []);
}
