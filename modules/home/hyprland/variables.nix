{ host, lib, ... } : {
  home.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = "1"; # Allows unfree packages

    # XDG for screen sharing
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";

    # Wayland support
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";

    # Qt theming
    QT_QPA_PLATFORMTHEME = "qt6ct";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    # QT_STYLE_OVERRIDE = "kvantum";

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

    # Styling fuzzy finder
    FZF_DEFAULT_OPTS = lib.mkForce " \
      --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
      --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
      --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
      --color=selected-bg:#45475A \
      --color=border:#6C7086,label:#CDD6F4
    ";
  };
}