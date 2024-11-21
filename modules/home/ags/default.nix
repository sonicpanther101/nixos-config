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

    extraPackages = with pkgs; [
      inputs.ags.packages.${pkgs.system}.apps
      inputs.ags.packages.${pkgs.system}.auth
      inputs.ags.packages.${pkgs.system}.battery
      inputs.ags.packages.${pkgs.system}.bluetooth
      # inputs.ags.packages.${pkgs.system}.cava
      inputs.ags.packages.${pkgs.system}.greet
      inputs.ags.packages.${pkgs.system}.hyprland
      inputs.ags.packages.${pkgs.system}.mpris
      inputs.ags.packages.${pkgs.system}.network
      inputs.ags.packages.${pkgs.system}.notifd
      inputs.ags.packages.${pkgs.system}.powerprofiles
      inputs.ags.packages.${pkgs.system}.river
      inputs.ags.packages.${pkgs.system}.tray
      inputs.ags.packages.${pkgs.system}.wireplumber
    ];
  };
}