{ host, lib, ... } : {
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    settings = {

      # autostart
      exec-once = [
        # Setting variables globally
        "systemctl --user import-environment"
        "dbus-update-activation-environment --systemd"

        # To be changed
        "sleep 1 && waybar"
        "copyq"

        # Set startup apps
        "nm-applet"
        "sleep 1 && hyprock"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        # "wl-copy" # Might clear the clipboard history on boot
      ]++ (if (host == "desktop") then [
        "openrgb --startminimized -b 0 -m direct"

        # Opening programs by default (not needed, just nice)
        "hyprctl dispatch exec '[workspace 1 silent] vivaldi --profile-directory=\"Default\"'"
        "hyprctl dispatch exec '[workspace 2 silent] Grayjay'"
        "hyprctl dispatch exec '[workspace 11 silent] beefweb_mpris'"
        "hyprctl dispatch exec '[workspace 12 silent] codium'"
        "hyprctl dispatch exec '[workspace 13 silent] kitty'"
        # "hyprctl dispatch focusmonitor HDMI-A-1 && hyprctl dispatch workspace 11 && hyprctl dispatch focusmonitor DP-1"
      ] else if (host == "laptop") then [
        "poweralertd"
      ] else [                                              
      ]);      

      # Old stuff not implemented yet 
      /* exec-once = 
        if (host == "desktop") then [
          "swww-daemon&"
          "my-ags"
        ] else [
          "swaybg -m fill -i $(find ~/Pictures/wallpapers/ -maxdepth 1 -type f)"
          "my-ags"
        ]; */

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

      bind = [
        # keybindings

        # terminal
        "SUPER, Return, exec, kitty"
        "ALT, Return, exec, kitty --title float_kitty"
        "SUPER SHIFT, Return, exec, kitty --start-as=fullscreen -o 'font_size=16'"

        # browser
        "SUPER, B, exec, vivaldi --profile-directory=\"Default\""
        "SUPER SHIFT, B, exec, vivaldi --profile-directory=\"Profile 1\""
        "SUPER SHIFT CTRL, B, exec, vivaldi --profile-directory=\"Profile 2\""

        # discord
        "SUPER SHIFT, D, exec, vesktop"

        # File browser
        "SUPER, E, exec, nemo"
        "ALT, E, exec, nemo"

        # ags
        "SUPER, R, exec, wofi --show drun"
        # "SUPER, R, exec, my-ags"
        "SUPER SHIFT, R, exec, my-ags -l"
        "SUPER, D, exec, ags toggle app-launcher"
        "ALT, V, exec, copyq show"
        # "ALT, V, exec, ags toggle clipboard"
        "SUPER, G, exec, ags toggle apis"
        "SUPER, W, exec, ags toggle wallpaper"
        "SUPER SHIFT, W, exec, ags toggle mouse-helper"
        "SUPER, F1, exec, show-keybinds"

        # window controls
        "SUPER, Q, killactive,"
        "SUPER, F, fullscreen, 0"
        "SUPER, Space, togglefloating,"
        "SUPER, P, pseudo,"
        "SUPER, J, togglesplit,"
        "ALT, Tab, cyclenext"
        "ALT, Tab, bringactivetotop"
        "ALT SHIFT, Tab, cyclenext, prev"
        "ALT SHIFT, Tab, bringactivetotop"

        # vscode options
        "SUPER, V, exec, codium"
        "SUPER SHIFT, V, exec, codium ~/nixos-config"
        "SUPER SHIFT CTRL, V, exec, codium ~/nixos-config/modules/home/ags/ags"

        # misc
        "SUPER, C ,exec, hyprpicker -a"

        # screenshot
        "SUPER, S, exec, grimblast --notify --cursor copysave area ~/Pictures/screenshots/$(date +'%Y-%m-%d-At-%Ih%Mm%Ss').png"
        "SUPER SHIFT, S, exec, kooha"

        # switch focus
        "SUPER, left, movefocus, l"
        "SUPER, right, movefocus, r"
        "SUPER, up, movefocus, u"
        "SUPER, down, movefocus, d"

        "SUPER CTRL, c, movetoworkspace, emptynm"

        # window control
        "SUPER SHIFT, left, movewindow, l"
        "SUPER SHIFT, right, movewindow, r"
        "SUPER SHIFT, up, movewindow, u"
        "SUPER SHIFT, down, movewindow, d"
        "SUPER CTRL, left, resizeactive, -80 0"
        "SUPER CTRL, right, resizeactive, 80 0"
        "SUPER CTRL, up, resizeactive, 0 -80"
        "SUPER CTRL, down, resizeactive, 0 80"
        "SUPER ALT, left, moveactive,  -80 0"
        "SUPER ALT, right, moveactive, 80 0"
        "SUPER ALT, up, moveactive, 0 -80"
        "SUPER ALT, down, moveactive, 0 80"

        # switch workspace
        "SUPER, 1, exec, hyprsome workspace 1"
        "SUPER, 2, exec, hyprsome workspace 2"
        "SUPER, 3, exec, hyprsome workspace 3"
        "SUPER, 4, exec, hyprsome workspace 4"
        "SUPER, 5, exec, hyprsome workspace 5"
        "SUPER, 6, exec, hyprsome workspace 6"
        "SUPER, 7, exec, hyprsome workspace 7"
        "SUPER, 8, exec, hyprsome workspace 8"
        "SUPER, 9, exec, hyprsome workspace 9"
        "SUPER, 0, exec, hyprsome workspace 10"

        "SUPER SHIFT, 1, exec, hyprsome move 1"
        "SUPER SHIFT, 2, exec, hyprsome move 2"
        "SUPER SHIFT, 3, exec, hyprsome move 3"
        "SUPER SHIFT, 4, exec, hyprsome move 4"
        "SUPER SHIFT, 5, exec, hyprsome move 5"
        "SUPER SHIFT, 6, exec, hyprsome move 6"
        "SUPER SHIFT, 7, exec, hyprsome move 7"
        "SUPER SHIFT, 8, exec, hyprsome move 8"
        "SUPER SHIFT, 9, exec, hyprsome move 9"
        "SUPER SHIFT, 0, exec, hyprsome move 10"
        
        "SUPER, mouse_down, workspace, r-1"
        "SUPER, mouse_up, workspace, r+1"
      ];

      # keybinds that work even on lockscreen
      bindl = [
        # laptop brightness
        ",XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        "SUPER, XF86MonBrightnessUp, exec, brightnessctl set 100%+"
        "SUPER, XF86MonBrightnessDown, exec, brightnessctl set 100%-"

        # desktop brightness
        ",code:233, exec, ddcutil --display `hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | grep -q DP && echo 2 || echo 1` setvcp 10 + 10"
        ",code:232, exec, ddcutil --display `hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | grep -q DP && echo 2 || echo 1` setvcp 10 - 10"
        "SUPER, code:233, exec, ddcutil --display `hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | grep -q DP && echo 2 || echo 1` setvcp 10 100"
        "SUPER, code:232, exec, ddcutil --display `hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | grep -q DP && echo 2 || echo 1` setvcp 10 0"

        # shutdown options
        "SUPER, Escape, exec, hyprlock"
        "SUPER SHIFT, Escape, exec, my-sleep"
        "SUPER SHIFT CTRL, Escape, exec, my-shutdown"
        "SUPER SHIFT CTRL ALT, Escape, exec, reboot"
        ", switch:Lid Switch, exec, my-sleep"

        # media and volume controls
        ",XF86AudioRaiseVolume,exec, pamixer -i 2"
        ",XF86AudioLowerVolume,exec, pamixer -d 2"
        ",XF86AudioMute,exec, pamixer -t"
        ",XF86AudioPlay,exec, playerctl play-pause"
        ",XF86AudioNext,exec, playerctl next"
        ",XF86AudioPrev,exec, playerctl previous"
        ",XF86AudioStop, exec, playerctl stop"
      ];

      # mouse binding
      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      windowrule = [
        "float,title:^(float_kitty)$"
        "center,title:^(float_kitty)$"
        "size 950 600,title:^(float_kitty)$"
      ];

      # Old window rules

      # windowrule
      /* windowrule = [
        "float,imv"
        "center,imv"
        "size 1200 725,imv"
        "float,mpv"
        "center,mpv"
        "size 1200 725,mpv"
        "tile,Aseprite"
        "float,title:^(OpenRGB)$"
        "float,title:^(Open Folder)$"
        "center,title:^(Open Folder)$"
        "size 950 600,title:^(Open Folder)$"
        "float,title:^(Open File)$"
        "center,title:^(Open File)$"
        "size 950 600,title:^(Open File)$"
        "float,title:^(float_kitty)$"
        "center,title:^(float_kitty)$"
        "size 950 600,title:^(float_kitty)$"
        "float,title:^(gemini-ui)$"
        "move 100%-0%,title:^(gemini-ui)$"
        "size 500 750,title:^(gemini-ui)$"
        "pin,title:^(gemini-ui)$"
        "float,audacious"
        "workspace 8 silent, audacious"
        "pin,wofi"
        "float,wofi"
        "noborder,wofi"
        "tile, neovide"
        "idleinhibit focus,mpv"
        "float,udiskie"
        "float,title:^(Transmission)$"
        "float,title:^(Volume Control)$"
        "float,title:^(Firefox — Sharing Indicator)$"
        "move 0 0,title:^(Firefox — Sharing Indicator)$"
        "size 700 450,title:^(Volume Control)$"
        "move 40 55%,title:^(Volume Control)$"
        "opacity 0.9,codium"
        "opacity 0.9,vivaldi"
        "opacity 0.99,title:^(.*HiAnime.*)$"
        "opacity 0.99,title:^(.*YouTube.*)$"
        "opacity 0.99,title:^(.*Channel 4.*)$"
        "opacity 0.75,nemo"
      ]; */

      # windowrulev2
      /* windowrulev2 = [
        "float, title:^(Picture-in-Picture)$"
        "opacity 1.0 override 1.0 override, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
        "opacity 1.0 override 1.0 override, title:^(.*imv.*)$"
        "opacity 1.0 override 1.0 override, title:^(.*mpv.*)$"
        "opacity 1.0 override 1.0 override, class:(Aseprite)"
        "opacity 1.0 override 1.0 override, class:(Unity)"
        "idleinhibit focus, class:^(mpv)$"
        "idleinhibit fullscreen, class:^(firefox)$"
        "float,class:^(pavucontrol)$"
        "float,class:^(SoundWireServer)$"
        "float,class:^(.sameboy-wrapped)$"
        "float,class:^(file_progress)$"
        "float,class:^(confirm)$"
        "float,class:^(dialog)$"
        "float,class:^(download)$"
        "float,class:^(notification)$"
        "float,class:^(error)$"
        "float,class:^(confirmreset)$"
        "float,title:^(Open File)$"
        "float,title:^(branchdialog)$"
        "float,title:^(Confirm to replace files)$"
        "float,title:^(File Operation Progress)$"
      ]; */

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