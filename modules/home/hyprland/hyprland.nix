{ inputs, pkgs-stable, pkgs-unstable, ... } : {

  wayland.windowManager.hyprland  = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;

    configType = "hyprlang"; # Change when updating to lua

    plugins = [
      inputs.split-monitor-workspaces.packages.${pkgs-stable.stdenv.hostPlatform.system}.split-monitor-workspaces
    ];

    extraConfig = ''
      plugin {
        split-monitor-workspaces {
          monitor_priority = DP-1, HDMI-A-1
          max_workspaces = DP-1, 10
          max_workspaces = HDMI-A-1, 10
        }
      }
    '';

    # set the flake package
    package = pkgs-unstable.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
  };
}