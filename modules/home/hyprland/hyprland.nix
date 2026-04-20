{ inputs, pkgs-stable, pkgs-unstable, host, ... } : {

  wayland.windowManager.hyprland  = {
    enable = true;

    xwayland.enable = true;
    
    systemd.enable = true;

    # set the flake package
    package = if (host == "laptop-2")
      then
        inputs.hyprland-fixed.packages.${pkgs-stable.stdenv.hostPlatform.system}.hyprland
      else
        inputs.hyprland.packages.${pkgs-stable.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
  };
}