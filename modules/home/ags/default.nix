{ inputs, pkgs, ... }:
{
  imports = [
    inputs.ags.homeManagerModules.default

  ];

  home.packages = with pkgs; [
  ];

  programs.ags = {
    enable = true;
    configDir = null; # if ags dir is managed by home-manager, it'll end up being read-only. not too cool.
    # configDir = "./.config/ags";

    extraPackages = with inputs.ags.packages.${pkgs.system}; [
      # astal
      io

      apps
      auth
      battery
      bluetooth
      cava
      greet
      hyprland
      mpris
      network
      notifd
      powerprofiles
      river
      tray
      wireplumber
    ];
  };
}