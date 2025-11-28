{ host, ... } : {
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    settings = {

      binds = { scroll_event_delay = 0; };

      input = {
        # Keyboard: Add a layout and uncomment kb_options for Win+Space switching shortcut
        kb_layout = "us";
        # kb_options = grp:win_space_toggle;
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
      };

      misc = {
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
        pseudotile = "yes";
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
          # "workspaces, 1, 3.5, md3_decel, slide"
          "workspaces, 1, 3, fluent_decel, slide"
          # "workspaces, 1, 7, fluent_decel, slidefade 15%"
          # "specialWorkspace, 1, 3, md3_decel, slidefadevert 15%"
          "specialWorkspace, 1, 3, md3_decel, slidevert"
        ];
      };

      workspace = if (host == "desktop") then [
        "1,monitor:HDMI-A-1"
        "2,monitor:HDMI-A-1"
        "3,monitor:HDMI-A-1"
        "4,monitor:HDMI-A-1"
        "5,monitor:HDMI-A-1"
        "6,monitor:HDMI-A-1"
        "7,monitor:HDMI-A-1"
        "8,monitor:HDMI-A-1"
        "9,monitor:HDMI-A-1"
        "10,monitor:HDMI-A-1"

        "11,monitor:DP-1"
        "12,monitor:DP-1"
        "13,monitor:DP-1"
        "14,monitor:DP-1"
        "15,monitor:DP-1"
        "16,monitor:DP-1"
        "17,monitor:DP-1"
        "18,monitor:DP-1"
        "19,monitor:DP-1"
        "20,monitor:DP-1"
      ] else [];

      monitor = if (host == "desktop") then [
        "HDMI-A-1,1920x1080@100,0x100,1"
        "DP-1,2560x1440@144.01,1920x0,1.066667"
      ] else [",preferred,auto,1.9"];

      xwayland.force_zero_scaling = true;
    };
  };
}