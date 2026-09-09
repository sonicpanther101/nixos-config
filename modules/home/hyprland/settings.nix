{ host, lib, isLaptop, ... } : 
let
  # Monitor descriptions extracted directly from hyprctl
  dp1Desc = "desc:ASUSTek COMPUTER INC VG27AQ1A S9LMQS099860";
  hdmi1Desc = "desc:AOC 27B30H 1AQQ7HA015555";
in
{
  wayland.windowManager.hyprland = {
    settings = {

      device = lib.optionals (host == "laptop-2") [{
        name = "wacom-hid-4915-pen";
        output = "eDP-1";
      }];

      binds = { scroll_event_delay = 0; };

      input = {
        kb_layout = "us";
        numlock_by_default = false;
        repeat_delay = 250;
        repeat_rate = 50;

        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          clickfinger_behavior = true;
          scroll_factor = 0.5;
        };

        follow_mouse = 1;
        accel_profile = "flat";
        sensitivity = 0.6;
      };

      cursor.no_warps = true;
      debug.disable_logs = false;

      general = {
        layout = "dwindle";
        gaps_in = 3;
        gaps_out = 6;
        gaps_workspaces = 10;
        border_size = 2;
        "col.active_border" = "rgb(89b4fa)";
      };

      misc = {
        allow_session_lock_restore = true;
        disable_autoreload = true;
        disable_hyprland_logo = true;
        always_follow_on_dnd = true;
        layers_hog_keyboard_focus = true;
        animate_manual_resizes = false;
        enable_swallow = true;
        focus_on_activate = true;
      };

      dwindle = {
        force_split = 0;
        special_scale_factor = 1.0;
        split_width_multiplier = 1.0;
        use_active_for_splits = true;
        preserve_split = true;
        smart_resizing = false;
      };

      master = {
        special_scale_factor = 1;
      };

      decoration = {
        rounding = 3;
        active_opacity = 1.0;
        inactive_opacity = 0.98;
        fullscreen_opacity = 1.0;

        blur = {
          enabled = true;
          size = 1;
          special = false;
          passes = 1;
          brightness = 1;
          contrast = 1;
          ignore_opacity = true;
          noise = 0;
          new_optimizations = true;
          xray = false;
        };

        dim_inactive = true;
        dim_strength = 0.02;
        dim_special = 0;
      };

      animations = {
        enabled = true;
        bezier = [
          "md3_decel, 0.05, 0.7, 0.1, 1"
          "md3_accel, 0.3, 0, 0.8, 0.15"
          "overshot, 0.05, 0.9, 0.1, 1.1"
          "crazyshot, 0.1, 1.5, 0.76, 0.92"
          "hyprnostretch, 0.05, 0.9, 0.1, 1.0"
          "fluent_decel, 0.1, 1, 0, 1"
          "easeInOutCirc, 0.85, 0, 0.15, 1"
          "easeOutCirc, 0, 0.55, 0.45, 1"
          "easeOutExpo, 0.16, 1, 0.3, 1"
        ];
        animation = [
          "windows, 1, 2, md3_decel, popin 60%"
          "border, 1, 10, default"
          "fade, 1, 2.5, md3_decel"
          "workspaces, 1, 3, fluent_decel, slide"
          "specialWorkspace, 1, 3, md3_decel, slidevert"
        ];
      };

      # Safely generate workspace-to-monitor bindings only for desktop
      workspace = lib.optionals (host == "desktop") (
        (map (i: "${toString i},monitor:${dp1Desc}") (lib.range 1 10)) ++
        (map (i: "${toString i},monitor:${hdmi1Desc}") (lib.range 11 20))
      );

      monitor = if host == "desktop" then [
        "${dp1Desc},2560x1440@170,0x0,1.3333"
        "${hdmi1Desc},1920x1080@100,1921x0,1"
      ] else if isLaptop then
        [",preferred,auto,2"]
      else [",preferred,auto,1"];

      xwayland.force_zero_scaling = true;
    };
  };
}
