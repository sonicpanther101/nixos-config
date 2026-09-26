{ inputs, pkgs-stable, isLaptop, isHighPower, lib, ... } : {

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;

    configType = "lua";

    plugins = [
      inputs.split-monitor-workspaces.packages.${pkgs-stable.stdenv.hostPlatform.system}.split-monitor-workspaces
    ] ++ lib.optionals isLaptop [
      inputs.hyprgrass.packages.${pkgs-stable.stdenv.hostPlatform.system}.default
    ];

    extraConfig =
      ''
        local smw = require("plugins.split-monitor-workspaces")
        smw.setup({
          monitor_priority = "DP-1, HDMI-A-1, eDP-1, Virtual-1",
          max_workspaces = { "DP-1 10", "HDMI-A-1 10", "eDP-1 10", "Virtual-1 10" },
        })
      ''
      + lib.optionalString isLaptop ''
        hl.config({
          plugin = {
            hyprgrass = {
              sensitivity = 3.0,
              workspace_swipe_fingers = 5,
              workspace_swipe_edge = "none",
              long_press_delay = 400,
              resize_on_border_long_press = true,
              edge_margin = 10,
            },
          },
        })
      ''
      + ''
        hl.config({
          gestures = {
            workspace_swipe_cancel_ratio = 0.15,
          },
        })
      '';

    # Set the flake package
    package = inputs.hyprland.packages.${pkgs-stable.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs-stable.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  home = {
    # Symlink Lua config files from nixos-config repo (true symlinks, no rebuild needed)
    activation.symlink-hyprland-lua = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      src_dir="${builtins.path { name = "nixos-config-hyprland-lua"; path = ./lua; }}"
      for f in keybinds autostart windowrules hyprgrass-gestures; do
        ln -sf "$src_dir/$f.lua" "$HOME/.config/hypr/$f.lua"
      done
    '';

    # Session variables for conditional startup
    sessionVariables = {
      IS_LAPTOP = lib.mkIf isLaptop "1";
      IS_HIGH_POWER = lib.mkIf isHighPower "1";
    };
  };
}
