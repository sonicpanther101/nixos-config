{ inputs, pkgs-unstable, pkgs-stable, ... } : {

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  home.packages = with pkgs-unstable; [
    kitty
    os-prober
    vlc
    vivaldi
    vscodium-fhs
    nemo-with-extensions
    adwaita-icon-theme
    p7zip
    unrar
    tree
    grayjay
    bottles
    ghostty
    wofi
    resources
    htop
    playerctl
    pamixer                           # pulseaudio command line mixer
    waybar-mpris
  ] ++ (with pkgs-stable; [
    corefonts
    noto-fonts
    noto-fonts-cjk-sans  # Chinese, Japanese and Korean glyphs
    noto-fonts-emoji
    noto-fonts-extra
    ipafont
  ]);
}