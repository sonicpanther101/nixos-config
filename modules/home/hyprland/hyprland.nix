{ inputs, pkgs-stable, isLaptop, isHighPower, lib, ... } :
let
  system = pkgs-stable.stdenv.hostPlatform.system;

  # hyprgrass is a real compiled (.so) Hyprland plugin - it needs
  # `hl.plugin.load()` (see below).
  hyprgrassPkg = inputs.hyprgrass.packages.${system}.default;
  pluginSo = pkg: "${pkg}/lib/lib${pkg.pname}.so";

  # split-monitor-workspaces is NOT a compiled plugin as of the Lua config
  # migration (the .so target in its flake is only the old, deprecated
  # pre-0.55 C++ plugin - see its docs/cpp-plugin.md). Since Hyprland 0.55 it
  # ships as a plain Lua package meant to be required directly:
  # https://github.com/zjeffer/split-monitor-workspaces#installation
  # says to `git clone` it into `~/.config/hypr/plugins/split-monitor-workspaces`
  # and `require("plugins.split-monitor-workspaces")`. We get the same result
  # in Nix by symlinking the flake input's source there instead (done in the
  # activation script below) - no `hl.plugin.load`/`hyprctl plugin load`
  # involved at all, which is why that never worked.
  smwSrc = inputs.split-monitor-workspaces;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;

    configType = "lua";

    plugins = lib.optionals isLaptop [
      hyprgrassPkg
    ];

    extraConfig =
      # Needed for require("plugins.split-monitor-workspaces") to find the
      # symlinked source below; Hyprland's require() doesn't look inside
      # subdirectories for an init.lua by default (only exact `name.lua`
      # files), so this mirrors the plugin's own README instructions.
      ''
        do
          local hypr_dir = os.getenv("HOME") .. "/.config/hypr"
          package.path = package.path .. ";" .. hypr_dir .. "/?.lua;" .. hypr_dir .. "/?/init.lua"
        end

        local smw = require("plugins.split-monitor-workspaces")
        smw.setup({
          -- 10 workspaces per monitor (this is also the plugin's own default).
          workspace_count = 10,
          -- Determines which monitor gets the lowest workspace IDs; must be
          -- a list, not the old hyprlang-style comma-separated string.
          monitor_priority = { "DP-1", "HDMI-A-1", "eDP-1", "Virtual-1" },
        })
      ''
      + lib.optionalString isLaptop ''
        hl.plugin.load(${lib.generators.toLua { } (pluginSo hyprgrassPkg)})
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

      mkdir -p "$HOME/.config/hypr/plugins"
      # If a real directory already sits here (e.g. from manually following
      # the plugin's own README, which says to `git clone` it into this exact
      # path), `ln -sfn` will NOT replace it - it'll silently drop the symlink
      # *inside* it instead (same behavior as `cp` into a directory), leaving
      # require("plugins.split-monitor-workspaces") unable to find init.lua.
      # `-n` only protects against dereferencing an existing *symlink*, not a
      # real directory. Remove any non-symlink first so the ln below actually
      # replaces the path.
      smw_link="$HOME/.config/hypr/plugins/split-monitor-workspaces"
      if [ -e "$smw_link" ] && [ ! -L "$smw_link" ]; then
        rm -rf "$smw_link"
      fi
      ln -sfn "${smwSrc}" "$smw_link"
    '';

    # Session variables for conditional startup
    sessionVariables = {
      IS_LAPTOP = lib.mkIf isLaptop "1";
      IS_HIGH_POWER = lib.mkIf isHighPower "1";
    };
  };
}
