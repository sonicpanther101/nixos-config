{ host, lib, config, pkgs-stable, ... } :
let
  # `hyprctl dispatch dpms off` stopped working with the Lua config: hyprctl
  # dispatch now takes a Lua expression (e.g. hl.dsp.dpms({ action = "disable" })),
  # not the old "<dispatcher> <args>" form. That made both the 60s dpms listener
  # silently do nothing.
  #
  # The Lua expression contains braces, quotes and an `=`, which is awkward to
  # embed in hypridle's own hyprlang-style config, so it lives in a tiny wrapper
  # script instead. It uses the absolute path of the configured Hyprland's
  # hyprctl so it doesn't depend on hypridle's systemd PATH.
  hyprctl = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl";

  dpms = pkgs-stable.writeShellScript "hypridle-dpms" ''
    case "$1" in
      on)  action=enable ;;
      off) action=disable ;;
      *) echo "usage: hypridle-dpms {on|off}" >&2; exit 1 ;;
    esac
    exec ${hyprctl} dispatch "hl.dsp.dpms({ action = \"$action\" })"
  '';
in {
  services.hypridle = {
    enable = true;

    settings = {
      listener =
        # Screen off after 60s (not on laptop-2, the tablet)
        lib.optionals (host != "laptop-2") [
          {
            timeout = 60;
            on-timeout = "${dpms} off";
            on-resume = "${dpms} on";
          }
        ]
        ++ lib.optionals (host != "desktop") [
          {
            timeout = 600;
            on-timeout = "systemctl --user start hyprlock.service";
          }
          {
            timeout = 1800;
            on-timeout = "my-sleep";
          }
        ];
    };
  };
}
