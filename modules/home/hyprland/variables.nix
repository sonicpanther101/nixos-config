{ host, ... } : {
  home.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = "1"; # Allows unfree packages
    NIXOS_OZONE_WL = "1"; # Enables native Wayland for Electron/Chromium apps
    MOZ_ENABLE_WAYLAND = "1"; # Firefox native Wayland
    QT_QPA_PLATFORM = "wayland"; # Qt apps use Wayland 

    # Cursors
    HYPRCURSOR_THEME = "catppuccin-mocha-dark-cursors";
    HYPRCURSOR_SIZE = 22;
    XCURSOR_SIZE = 22;

    # Scaling
    GDK_SCALE = if (host == "laptop") then 2 else 1;
  };
}