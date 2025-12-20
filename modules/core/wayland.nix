{ inputs, pkgs-unstable, ... } : {
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    xdgOpenUsePortal = true;
    extraPortals = (with pkgs-unstable; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk

      # Disabled for screen share
      # xdg-desktop-portal-hyprland
    ]);
    config = {
      common.default = ["gtk"];
      hyprland.default = ["gtk" "hyprland"];
    };
  };
}