{ inputs, pkgs-unstable, ... } : {
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = (with pkgs-unstable; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk

      # Disabled for screen share
      # xdg-desktop-portal-wlr
    ]);
    config = {
      common.default = ["gtk"];
      hyprland.default = ["gtk" "hyprland"];
    };
  };

  # Wrap xdg-desktop-portal-hyprland to prevent qt6ct crashes
  systemd.user.services.xdg-desktop-portal-hyprland = {
    serviceConfig = {
      Environment = [
        "QT_QPA_PLATFORMTHEME="
        "QT_STYLE_OVERRIDE="
      ];
    };
  };
}