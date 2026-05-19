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

      hl.config({ 

        binds = { scroll_event_delay = 0 },

        cursor = { no_warps = true },
        decoration = {
          rounding = 3,
          active_opacity = 1.0,
          inactive_opacity = 0.98,
          fullscreen_opacity = 1.0,

          blur = {
            enabled = true,
            size = 1,
            special = false,
            passes = 1,
            brightness = 1,
            contrast = 1,
            ignore_opacity = true,
            noise = 0,
            new_optimizations = true,
            xray = false
          },

          dim_inactive = true,
          dim_strength = 0.02,
          dim_special = 0
        },

        dwindle = {
          force_split = 0,
          special_scale_factor = 1.0,
          split_width_multiplier = 1.0,
          use_active_for_splits = true,
          preserve_split = true,
          smart_resizing = false
        },

        general = {
          layout = "dwindle",
          gaps_in = 3,
          gaps_out = 6,
          gaps_workspaces = 10,
          border_size = 2,
          col = { active_border = "rgb(89b4fa)" }
        },

        input = {
          -- Keyboard: Add a layout and uncomment kb_options for Win+Space switching shortcut
          kb_layout = "us",
          -- kb_options = grp:win_space_toggle,
          numlock_by_default = false,
          repeat_delay = 250,
          repeat_rate = 50,

          touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            scroll_factor = 0.5
          },

          follow_mouse = 1,
          -- follow_mouse = 2, -- For bambu lab submenus
          accel_profile = "flat",
          sensitivity = 0.6
        },

        misc = {
          disable_autoreload = true,
          disable_hyprland_logo = true,
          always_follow_on_dnd = true,
          layers_hog_keyboard_focus = true,
          animate_manual_resizes = false,
          enable_swallow = true,
          focus_on_activate = true
        },

        master = { special_scale_factor = 1 },
      })
      hl.config({
        xwayland = {
          force_zero_scaling = true
        }
      })
    '' + (if host == "desktop" then ''
      hl.monitor({
        output = "DP-1",
        mode = "2560x1440@170",
        position = "0x0",
        scale = "1.3333"
      })
      hl.monitor({
        output = "HDMI-A-1",
        mode = "1920x1080@100",
        position = "1921x0",
        scale = "1"
      })
    '' + (
      builtins.concatStringsSep "\n" (builtins.genList (i:
        let n = i + 1; in
        ''
        hl.workspace_rule({ workspace = "${toString(n)}", monitor = "HDMI-A-1"})
        hl.workspace_rule({ workspace = "${toString(n+10)}", monitor = "DP-1"})
        '' ) 10)
    ) else ''
      hl.monitor({
        output = "",
        mode = "preferred",
        position = "auto",
        scale = "2"
      })
    '');
    
    settings = {

      device = lib.optionals (host == "laptop-2") [{
        name = "wacom-hid-4915-pen";
        output = "eDP-1";  # verify with hyprctl monitors
      }];
    };
  };
}