{ host, ... } : {
  home.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = "1"; # Allows unfree packages

    # Wayland support
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";

    # Qt theming
    QT_QPA_PLATFORMTHEME = "qt5ct";
    QT_STYLE_OVERRIDE = "kvantum";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";

    # App specific
    ANKI_WAYLAND = "1";
    _JAVA_AWT_WM_NONEREPARENTING = "1";
    DIRENV_LOG_FORMAT = "";

    # Cursors
    HYPRCURSOR_THEME = "catppuccin-mocha-dark-cursors";
    HYPRCURSOR_SIZE = 22;
    XCURSOR_SIZE = 22;

    # Scaling
    GDK_SCALE = if (host == "laptop") then 2 else 1;

    # Only keep these if you have specific GPU issues:
    # WLR_NO_HARDWARE_CURSORS = "1";
    # WLR_DRM_NO_ATOMIC = "1";
  };
}