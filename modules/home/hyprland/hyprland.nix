{ inputs, pkgs-stable, isLaptop, lib, ... } : {

  wayland.windowManager.hyprland  = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;

    configType = "hyprlang"; # Change when updating to lua

    plugins = [
      inputs.split-monitor-workspaces.packages.${pkgs-stable.stdenv.hostPlatform.system}.split-monitor-workspaces
    ] ++ lib.optionals isLaptop [
      inputs.hyprgrass.packages.${pkgs-stable.stdenv.hostPlatform.system}.default
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
          # Tablet screens generally need more sensitivity than the 1.0 default.
          sensitivity = 3.0

          # must be >= 3. Deliberately set high (out of the way of the 3/4-finger
          # discrete gestures below) since workspace switching is handled by the
          # swipe:4:l/r binds -> split-cycleworkspaces instead of this drag-to-follow
          # continuous swipe.
          workspace_swipe_fingers = 5

          # continuous edge-drag workspace switching, separate from workspace_swipe_fingers.
          # Disabled (set to a non l/r/u/d value) because every edge below is already
          # used for a discrete quick-launch gesture and would otherwise collide with it.
          workspace_swipe_edge = u

          # in milliseconds
          long_press_delay = 400

          # resize windows by long-pressing on window borders and gaps.
          # If general:resize_on_border is enabled, general:extend_border_grab_area is
          # used for floating windows
          resize_on_border_long_press = true

          # in pixels, the distance from the edge that is considered an edge
          edge_margin = 10

          # --- Edge swipes: quick-launch, using default apps/audio manager ---
          # swipe left from right edge -> xournalpp
          hyprgrass-bind = , edge:r:l, exec, xournalpp
          # swipe up from bottom edge -> browser
          hyprgrass-bind = , edge:d:u, exec, vivaldi --profile-directory="Default" --allowlisted-extension-id=clngdbkpkpeebahjckkjfobafhncgmne
          # swipe right from bottom edge -> work browser
          hyprgrass-bind = , edge:d:r, exec, vivaldi --profile-directory="Profile 1"
          # swipe down from left edge -> volume down
          hyprgrass-bind = , edge:l:d, exec, pamixer -d 4
          # swipe up from left edge -> volume up
          hyprgrass-bind = , edge:l:u, exec, pamixer -i 4

          # --- 4-finger swipes: workspaces + window state (from the cheatsheet) ---
          # workspace nav uses split-cycleworkspaces instead of the plain "workspace" dispatcher
          hyprgrass-bind = , swipe:4:l, split-cycleworkspaces, +1
          hyprgrass-bind = , swipe:4:r, split-cycleworkspaces, -1
          hyprgrass-bind = , swipe:4:d, fullscreen, 0
          hyprgrass-bind = , swipe:4:u, togglefloating

          # --- 3-finger swipes: focus + layout (from the cheatsheet) ---
          hyprgrass-bind = , swipe:3:l, movefocus, l
          hyprgrass-bind = , swipe:3:r, movefocus, r
          hyprgrass-bind = , swipe:3:d, layoutmsg, togglesplit
          hyprgrass-bind = , swipe:3:u, layoutmsg, swapsplit

          # tap with 3 fingers -> terminal
          hyprgrass-bind = , tap:3, exec, kitty

          # pinch in with 3 fingers -> file manager
          hyprgrass-bind = , pinch:3:i, exec, nemo

          # 5-finger tap/pinch -> close window (from the cheatsheet)
          hyprgrass-bind = , tap:5, killactive
          hyprgrass-bind = , pinch:5:i, killactive

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
