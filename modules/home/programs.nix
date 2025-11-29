{ lib, pkgs-unstable, pkgs-stable, ... } : {

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
  home.file.".config/qt5ct/colors".source = pkgs-stable.fetchFromGitHub {
    owner = "catppuccin";
    repo = "qt5ct";
    rev = "main";
    hash = "sha256-wDj6kQ2LQyMuEvTQP6NifYFdsDLT+fMCe3Fxr8S783w=";
  } + "/themes/catppuccin-mocha-blue.conf";
  home.file.".config/qt6ct/colors".source = pkgs-stable.fetchFromGitHub {
    owner = "catppuccin";
    repo = "qt5ct";
    rev = "main";
    hash = "sha256-wDj6kQ2LQyMuEvTQP6NifYFdsDLT+fMCe3Fxr8S783w=";
  } + "/themes/catppuccin-mocha-blue.conf";
}