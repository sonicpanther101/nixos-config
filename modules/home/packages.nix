{ inputs, pkgs-unstable, pkgs-stable, ... } : {

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  home.packages = with pkgs-unstable; [
    kitty
    os-prober
    vivaldi
    vscodium-fhs
    firefox
    kdePackages.dolphin
    grayjay
    bottles
    ghostty
    wofi
    resources
    htop
    inputs.erosanix.packages.x86_64-linux.foobar2000
  ];
}