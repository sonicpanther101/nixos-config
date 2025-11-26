{ inputs, pkgs-stable, ... } : {

  systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];

  wayland.windowManager.hyprland  = {
    enable = true;

    xwayland = {
      enable = true;
    };
    systemd.enable = true;

    # set the flake package
    package = inputs.hyprland.packages.${pkgs-stable.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs-stable.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };
}