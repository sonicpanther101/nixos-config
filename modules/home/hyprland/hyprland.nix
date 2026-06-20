{ inputs, pkgs-stable, isLaptop, lib, ... } : {

  wayland.windowManager.hyprland  = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;

    configType = "hyprlang"; # Change when updating to lua

    plugins = [
      inputs.split-monitor-workspaces.packages.${pkgs-stable.stdenv.hostPlatform.system}.split-monitor-workspaces
    ] ++ lib.optionals isLaptop [
      inputs.hyprgrass.packages.${pkgs-stable.system}.default
    ];

    extraConfig = ''
      plugin {
        split-monitor-workspaces {
          monitor_priority = DP-1, HDMI-A-1, eDP-1, Virtual-1
          max_workspaces = DP-1, 10
          max_workspaces = HDMI-A-1, 10
          max_workspaces = eDP-1, 10
          max_workspaces = Virtual-1, 10
        }
    '' + (if isLaptop then ''
        touch_gestures {
          # The default sensitivity is probably too low on tablet screens,
          # I recommend turning it up to 4.0
          sensitivity = 1.0

          # must be >= 3
          workspace_swipe_fingers = 3

          # switching workspaces by swiping from an edge, this is separate from workspace_swipe_fingers
          # and can be used at the same time
          # possible values: l, r, u, or d
          # to disable it set it to anything else
          workspace_swipe_edge = d

          # in milliseconds
          long_press_delay = 400

          # resize windows by long-pressing on window borders and gaps.
          # If general:resize_on_border is enabled, general:extend_border_grab_area is
          # used for floating windows
          resize_on_border_long_press = true

          # in pixels, the distance from the edge that is considered an edge
          edge_margin = 10

          # swipe left from right edge
          hyprgrass-bind = , edge:r:l, workspace, +1

          # swipe up from bottom edge
          hyprgrass-bind = , edge:d:u, exec, firefox

          # swipe down from left edge
          hyprgrass-bind = , edge:l:d, exec, pactl set-sink-volume @DEFAULT_SINK@ -4%

          # swipe down with 4 fingers
          hyprgrass-bind = , swipe:4:d, killactive

          # swipe diagonally left and down with 3 fingers
          # l (or r) must come before d and u
          hyprgrass-bind = , swipe:3:ld, exec, foot

          # tap with 3 fingers
          hyprgrass-bind = , tap:3, exec, foot

          # pinch in with 3 fingers
          hyprgrass-bind = , pinch:3:i, exec, foot

          # longpress can trigger mouse binds:
          hyprgrass-bindm = , longpress:2, movewindow
          hyprgrass-bindm = , longpress:3, resizewindow 
        }
      }
      gestures {
        workspace_swipe_cancel_ratio = 0.15
      }
    '' else ''
      }
    '');

    # set the flake package
    package = inputs.hyprland.packages.${pkgs-stable.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs-stable.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };
}
