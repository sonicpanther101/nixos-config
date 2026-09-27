{ inputs, pkgs-stable, isLaptop, isHighPower, lib, ... } :
let
  system = pkgs-stable.stdenv.hostPlatform.system;

  smwPkg = inputs.split-monitor-workspaces.packages.${system}.split-monitor-workspaces;
  hyprgrassPkg = inputs.hyprgrass.packages.${system}.default;

  # home-manager's `plugins` option only loads plugins *after* the config has
  # already been parsed once (it schedules `hyprctl plugin load ...` as an
  # exec-once/"hyprland.start" hook). That's too late for a Lua config that
  # does `require("plugins.split-monitor-workspaces")` synchronously while
  # parsing - hence "module 'plugins.split-monitor-workspaces' not found".
  # Hyprland 0.55+'s Lua API has a dedicated function for exactly this case:
  # `hl.plugin.load(path)`, called directly in the config, synchronously,
  # before anything that needs the plugin. Same .so naming convention
  # home-manager itself uses (lib/lib<pname>.so).
  pluginSo = pkg: "${pkg}/lib/lib${pkg.pname}.so";
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;

    configType = "lua";

    plugins = [
      smwPkg
    ] ++ lib.optionals isLaptop [
      hyprgrassPkg
    ];

    extraConfig =
      ''
        hl.plugin.load(${lib.generators.toLua { } (pluginSo smwPkg)})
      ''
      + lib.optionalString isLaptop ''
        hl.plugin.load(${lib.generators.toLua { } (pluginSo hyprgrassPkg)})
      ''
      + ''
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
      ''
      # These files are symlinked (not copied) by the activation script below,
      # so they must be require()'d here or Hyprland never loads them.
      + ''
        require("keybinds")
        require("autostart")
        require("windowrules")
      ''
      + lib.optionalString isLaptop ''
        require("hyprgrass-gestures")
      '';

    # Set the flake package
    package = inputs.hyprland.packages.${system}.hyprland;
    portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
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
