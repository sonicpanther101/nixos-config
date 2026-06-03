{ lib, pkgs-unstable, pkgs-stable, username, inputs, hasNvidia, ... } : let 

  catppuccin-qt5ct = pkgs-stable.fetchFromGitHub {
    owner = "catppuccin";
    repo = "qt5ct";
    rev = "main";
    hash = "sha256-wDj6kQ2LQyMuEvTQP6NifYFdsDLT+fMCe3Fxr8S783w=";
  };

  catppuccin-kvantum = pkgs-stable.fetchFromGitHub {
    owner = "catppuccin";
    repo = "Kvantum";
    rev = "main";
    hash = "sha256-V5Upqkil9Q2MeEPtEAemirbJxnEyYcM3Z8jiyz//ccw=";
  };

in {

  # Foobar2000
  home.file = {
    ".config/beefweb_mpris/config.yaml".source =
      "${pkgs-stable.callPackage ../../packages/foobar2000.nix { inherit pkgs-stable inputs username; }}/share/beefweb_mpris/config.yaml";
  };

  programs = {
    nh = {
      enable = true;
      clean.enable = true;
    };

    # Cat alternative
    bat = {
      enable = true;
      config = {
        pager = "less -FR";
      };
    };

    # Monitor of resources
    btop = {
      enable = true;
      package = if hasNvidia then pkgs-stable.btop-cuda else pkgs-stable.btop;
    };

    # Audio visualiser
    cava = {
      enable = true;
      settings = {
        general = {
          framerate = 30;
        };
        input.method = "pipewire"; 
      };
    };

    # Shell extension that manages your environment
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Styling to override stylix
    bat.config.theme = lib.mkForce "Catppuccin Mocha";
    fzf.colors = lib.mkForce {
      "bg+" = "#313244";
    };
  };

  # Kvantum
  home.file.".config/Kvantum/catppuccin-mocha-blue".source = "${catppuccin-kvantum}/themes/catppuccin-mocha-blue";
  home.file.".config/Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=catppuccin-mocha-blue
  '';

  # QT
  home.file.".config/qt5ct/colors/catppuccin-mocha-mauve.conf".source = "${catppuccin-qt5ct}/themes/catppuccin-mocha-blue.conf";
  home.file.".config/qt6ct/colors/catppuccin-mocha-mauve.conf".source = "${catppuccin-qt5ct}/themes/catppuccin-mocha-blue.conf";
  home.file.".config/qt5ct/qt5ct.conf".text = ''
    [Appearance]
    style=kvantum
    custom_palette=true
    color_scheme_path=/home/${username}/.config/qt5ct/colors/catppuccin-mocha-mauve.conf
    [Fonts]
    fixed="JetBrainsMono Nerd Font,12"
    general="DejaVu Sans,12"
  '';
  home.file.".config/qt6ct/qt6ct.conf".text = ''
    [Appearance]
    style=kvantum
    custom_palette=true
    color_scheme_path=/home/${username}/.config/qt6ct/colors/catppuccin-mocha-mauve.conf
    [Fonts]
    fixed="JetBrainsMono Nerd Font,12"
    general="DejaVu Sans,12"
  '';
}