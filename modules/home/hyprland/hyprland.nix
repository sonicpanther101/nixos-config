{ inputs, pkgs-stable, pkgs-unstable, ... } : {

  wayland.windowManager.hyprland  = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;

    configType = "lua";

    plugins = [
      inputs.split-monitor-workspaces.packages.${pkgs-stable.stdenv.hostPlatform.system}.split-monitor-workspaces
    ];

    # set the flake package
    package = inputs.hyprland.packages.${pkgs-stable.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
  };
}