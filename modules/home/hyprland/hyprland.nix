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
      ''
        do
          local hypr_dir = os.getenv("HOME") .. "/.config/hypr"
          package.path = package.path .. ";" .. hypr_dir .. "/?.lua;" .. hypr_dir .. "/?/init.lua"
        end

        local smw = require("plugins.split-monitor-workspaces")

        -- Function to initialize smw configuration
        local function init_smw()
          smw.setup({
            workspace_count = 10,
            monitor_priority = { "HDMI-A-1", "DP-1", "eDP-1", "Virtual-1" },
          })
        end

        -- Run initial setup
        init_smw()
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
      + lib.optionalString isHighPower "IS_HIGH_POWER = true\n"
      + lib.optionalString isLaptop "IS_LAPTOP = true\n"
      + ''
        -- Load keybinds and other config files
        require("keybinds")
        require("autostart")
        require("windowrules")

        -- Re-run setup after all modules/monitors are loaded to ensure offsets bind correctly
        smw.setup({
          workspace_count = 10,
          monitor_priority = { "DP-1", "HDMI-A-1", "eDP-1", "Virtual-1" },
        })
      ''
      + lib.optionalString isLaptop ''
        require("hyprgrass-gestures")
      '';

    # Set the flake package
    package = inputs.hyprland.packages.${system}.hyprland;
    portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
  };

  # Symlink Lua config files directly from the local git repo (no nix store copying)
  home.activation.symlink-hyprland-lua = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    repo_lua_dir="$HOME/nixos-config/modules/home/hyprland/lua"

    for f in keybinds autostart windowrules hyprgrass-gestures; do
      ln -sf "$repo_lua_dir/$f.lua" "$HOME/.config/hypr/$f.lua"
    done

    mkdir -p "$HOME/.config/hypr/plugins"

    smw_link="$HOME/.config/hypr/plugins/split-monitor-workspaces"
    if [ -e "$smw_link" ] && [ ! -L "$smw_link" ]; then
      rm -rf "$smw_link"
    fi
    ln -sfn "${smwSrc}" "$smw_link"
  '';
}
