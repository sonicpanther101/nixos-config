{ inputs, pkgs-unstable, pkgs-stable, ... } : {

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  home.packages = with pkgs-unstable; [
    kitty
    os-prober
    vlc
    vivaldi
    vscodium-fhs
    firefox
    kdePackages.dolphin
    nemo-with-extensions
    adwaita-icon-theme
    p7zip
    unrar
    grayjay
    bottles
    ghostty
    wofi
    resources
    htop
    playerctl
    pamixer                           # pulseaudio command line mixer
    inputs.erosanix.packages.x86_64-linux.foobar2000
  ];
}