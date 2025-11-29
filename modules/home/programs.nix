{ lib, pkgs-unstable, pkgs-stable, username, ... } : {

  programs.nh = {
    enable = true;
    clean.enable = true;
  };

  # Temporary notifications daemon to shut grimblast up
  services.mako.enable = true;

  # Cat alternative
  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR";
    };
  };

  # Browser
  programs.chromium = {
    enable = true;
    package = pkgs-unstable.vivaldi;
    extensions = [ "clngdbkpkpeebahjckkjfobafhncgmne" ];
  };

  # Styling to override stylix
  programs.bat.config.theme = lib.mkForce "Catppuccin Mocha";
  programs.fzf.colors = lib.mkForce {
    "bg+" = "#313244";
  };

  # QT
  home.file.".config/qt5ct/colors/catppuccin-mocha-mauve.conf".source = pkgs-stable.fetchFromGitHub {
    owner = "catppuccin";
    repo = "qt5ct";
    rev = "main";
    hash = "sha256-wDj6kQ2LQyMuEvTQP6NifYFdsDLT+fMCe3Fxr8S783w=";
  } + "/themes/catppuccin-mocha-blue.conf";
  home.file.".config/qt6ct/colors/catppuccin-mocha-mauve.conf".source = pkgs-stable.fetchFromGitHub {
    owner = "catppuccin";
    repo = "qt5ct";
    rev = "main";
    hash = "sha256-wDj6kQ2LQyMuEvTQP6NifYFdsDLT+fMCe3Fxr8S783w=";
  } + "/themes/catppuccin-mocha-blue.conf";
  home.file.".config/qt5ct/qt5ct.conf".text = lib.mkForce ''
    [Appearance]
    style=kvantum
    custom_palette=true
    color_scheme_path=/home/${username}/.config/qt5ct/colors/catppuccin-mocha-mauve.conf
    [Fonts]
    fixed="JetBrainsMono Nerd Font,12"
    general="DejaVu Sans,12"
  '';
  home.file.".config/qt6ct/qt6ct.conf".text = lib.mkForce ''
    [Appearance]
    style=kvantum
    custom_palette=true
    color_scheme_path=/home/${username}/.config/qt6ct/colors/catppuccin-mocha-mauve.conf
    [Fonts]
    fixed="JetBrainsMono Nerd Font,12"
    general="DejaVu Sans,12"
  '';
}