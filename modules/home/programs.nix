{ lib, pkgs-unstable, ... } : {

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

  # Styling
  programs.bat.config.theme = lib.mkForce "Catppuccin Mocha";
  programs.fzf.colors = lib.mkForce {
    "bg+" = "#313244";
  };
}