{ host, lib, ... } : {
  wayland.windowManager.hyprland = {

    extraConfig = ''
      hl.curve("md3_decel",      { type = "bezier", points = { {0.05, 0.7},  {0.1,  1}    } })
      hl.curve("md3_accel",      { type = "bezier", points = { {0.3,  0},    {0.8,  0.15} } })
      hl.curve("overshot",       { type = "bezier", points = { {0.05, 0.9},  {0.1,  1.1}  } })
      hl.curve("crazyshot",      { type = "bezier", points = { {0.1,  1.5},  {0.76, 0.92} } })
      hl.curve("hyprnostretch",  { type = "bezier", points = { {0.05, 0.9},  {0.1,  1.0}  } })
      hl.curve("fluent_decel",   { type = "bezier", points = { {0.1,  1},    {0,    1}    } })
      hl.curve("easeInOutCirc",  { type = "bezier", points = { {0.85, 0},    {0.15, 1}    } })
      hl.curve("easeOutCirc",    { type = "bezier", points = { {0,    0.55}, {0.45, 1}    } })
      hl.curve("easeOutExpo",    { type = "bezier", points = { {0.16, 1},    {0.3,  1}    } })

      hl.animation({ leaf = "windows",         enabled = true, speed = 2,   bezier = "md3_decel",   style = "popin 60%" })
      hl.animation({ leaf = "border",          enabled = true, speed = 10,  bezier = "default" })
      hl.animation({ leaf = "fade",            enabled = true, speed = 2.5, bezier = "md3_decel" })
      hl.animation({ leaf = "workspaces",      enabled = true, speed = 3,   bezier = "fluent_decel", style = "slide" })
      hl.animation({ leaf = "specialWorkspace",enabled = true, speed = 3,   bezier = "md3_decel",    style = "slidevert" })

      hl.config({ cursor = { no_warps = true } })
    '';
    
    settings = {

      device = lib.optionals (host == "laptop-2") [{
        name = "wacom-hid-4915-pen";
        output = "eDP-1";  # verify with hyprctl monitors
      }];

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
        # follow_mouse = 2; # For bambu lab submenus
        accel_profile = "flat";
        sensitivity = 0.6;
      };

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

      # workspace = if (host != host) then [
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
        "DP-1,2560x1440@170,0x0,1.3333"
        "HDMI-A-1,1920x1080@100,1921x0,1"
      ] else [",preferred,auto,2"];

      xwayland.force_zero_scaling = true;
    };
  };
}