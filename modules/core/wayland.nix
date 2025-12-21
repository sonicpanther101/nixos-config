{ inputs, pkgs-unstable, ... } : {
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    xdgOpenUsePortal = true;
    extraPortals = (with pkgs-unstable; [
      inputs.hyprland.packages.${pkgs-stable.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk

      # Disabled for screen share
      # xdg-desktop-portal-wlr
    ]);
    config = {
      common.default = ["gtk"];
      hyprland.default = ["gtk" "hyprland"];
    };
  };
}