{ inputs, pkgs-unstable, ... } : {

  wayland.windowManager.hyprland  = {
    enable = true;

    xwayland = {
      enable = true;
    };
    systemd.enable = true;

    # set the flake package
    package = inputs.hyprland.packages.${pkgs-unstable.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs-unstable.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };
}