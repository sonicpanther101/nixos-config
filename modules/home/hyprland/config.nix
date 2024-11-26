{ host, ... }: 
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    settings = {
      
      gestures = {
        workspace_swipe = true;
        workspace_swipe_distance = 700;
        workspace_swipe_fingers = 4;
        workspace_swipe_cancel_ratio = 0.2;
        workspace_swipe_min_speed_to_force = 5;
        workspace_swipe_direction_lock = true;
        workspace_swipe_direction_lock_threshold = 10;
        workspace_swipe_create_new = true;
      };

      # autostart
      exec-once = 
        if (host == "desktop") then [
          "systemctl --user import-environment &"
          "hash dbus-update-activation-environment 2>/dev/null &"
          "dbus-update-activation-environment --systemd &"
          "nm-applet &"
          "swww-daemon&"
          "sleep 1 && swaylock"
          "hyprctl setcursor catppuccin-mocha-dark-cursors 22 &"
          "poweralertd &"
          "wl-paste --type text --watch cliphist store"
          "wl-paste --type image --watch cliphist store"
          "wl-copy &"
          "my-ags"
          "openrgb --startminimized -b 0 -m direct"
          "wlsunset -t 4000 -s 21:00 -S 06:30 -d 10 -g 1 &"
          "hyprctl dispatch exec '[workspace 1 silent] vivaldi --profile-directory=\"Default\"'"
          "hyprctl dispatch focusmonitor DP-2 && hyprctl dispatch workspace 11 && hyprctl dispatch focusmonitor DP-1"
        ] else [
          "systemctl --user import-environment &"
          "hash dbus-update-activation-environment 2>/dev/null &"
          "dbus-update-activation-environment --systemd &"
          "nm-applet &"
          "swaybg -m fill -i $(find ~/Pictures/wallpapers/ -maxdepth 1 -type f) &"
          "sleep 1 && swaylock"
          "hyprctl setcursor catppuccin-mocha-dark-cursors 22 &"
          "poweralertd &"
          "wl-paste --type text --watch cliphist store"
          "wl-paste --type image --watch cliphist store"
          "wl-copy &"
          "ags run /home/adam/nixos-config/modules/home/ags/new\ ags"
          "wlsunset -t 4000 -s 21:00 -S 06:30 -d 10 -g 1 &"
        ];

      binds = { scroll_event_delay = 0; };
      input = {
        # Keyboard: Add a layout and uncomment kb_options for Win+Space switching shortcut
        kb_layout = "us";
        # kb_options = grp:win_space_toggle;
        numlock_by_default = false;
        repeat_delay = 250;
        repeat_rate = 35;

        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          clickfinger_behavior = true;
          scroll_factor = 0.5;
        };

        follow_mouse = 1;
      };

      cursor.no_warps = true;
      debug.disable_logs = false;

      general = {
        "$mainMod" = "SUPER";
        layout = "dwindle";
        gaps_in = 0;
        gaps_out = 0;
        gaps_workspaces = 0;
        border_size = 1;
        border_part_of_window = false;
        no_border_on_floating = false;
        resize_on_border = true;
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
        no_gaps_when_only = true;
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
        no_gaps_when_only = false;
      };

      decoration = {
        rounding = 0;
        # active_opacity = 0.90;
        # inactive_opacity = 0.90;
        # fullscreen_opacity = 1.0;

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

        drop_shadow = false;

        shadow_ignore_window = true;
        shadow_offset = "0 2";
        shadow_range = 20;
        shadow_render_power = 3;

        dim_inactive = false;
        dim_strength = 0.1;
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
          "windows, 1, 3, md3_decel, popin 60%"
          "border, 1, 10, default"
          "fade, 1, 2.5, md3_decel"
          # "workspaces, 1, 3.5, md3_decel, slide"
          "workspaces, 1, 7, fluent_decel, slide"
          # "workspaces, 1, 7, fluent_decel, slidefade 15%"
          # "specialWorkspace, 1, 3, md3_decel, slidefadevert 15%"
          "specialWorkspace, 1, 3, md3_decel, slidevert"
        ];
      };

      bind = [
        # show keybinds list
        "$mainMod, F1, exec, show-keybinds"

        # keybindings
        # terminal
        "$mainMod, Return, exec, kitty"
        "ALT, Return, exec, kitty --title float_kitty"
        "$mainMod SHIFT, Return, exec, kitty --start-as=fullscreen -o 'font_size=16'"
        # browser
        "$mainMod, B, exec, hyprctl dispatch exec '[workspace 1 silent] vivaldi --profile-directory=\"Default\"'"
        "$mainMod SHIFT, B, exec, hyprctl dispatch exec '[workspace 2 silent] vivaldi --profile-directory=\"Profile 1\"'"
        "$mainMod SHIFT CTRL, B, exec, vivaldi --profile-directory=\"Profile 2\""
        # discord
        "$mainMod SHIFT, D, exec, hyprctl dispatch exec '[workspace 5 silent] vesktop'"
        "$mainMod, E, exec, nemo"
        # ags
        "$mainMod, R, exec, my-ags"
        "$mainMod SHIFT, R, exec, my-ags -l"
        "$mainMod, D, exec, ags toggle app-launcher"
        "$mainMod, G, exec, ags -t gemini-ui"
        "$ALT, V, exec, ags toggle clipboard"
        # window controls
        "$mainMod, Q, killactive,"
        "$mainMod, F, fullscreen, 0"
        "$mainMod, Space, togglefloating,"
        "$mainMod, P, pseudo,"
        "$mainMod, J, togglesplit,"
        "ALT, Tab, cyclenext"
        "ALT, Tab, bringactivetotop"
        "ALT SHIFT, Tab, cyclenext, prev"
        "ALT SHIFT, Tab, bringactivetotop"
        # shutdown options
        "$mainMod, Escape, exec, swaylock"
        "$mainMod SHIFT, Escape, exec, my-sleep"
        "$mainMod SHIFT CTRL, Escape, exec, my-shutdown"
        "$mainMod SHIFT CTRL ALT, Escape, exec, reboot"
        # vscode options
        "$mainMod, V, exec, codium"
        "$mainMod SHIFT, V, exec, codium ~/nixos-config"
        "$mainMod SHIFT CTRL, V, exec, codium ~/nixos-config/modules/home/ags/ags"
        # misc
        "$mainMod, C ,exec, hyprpicker -a"
        "$mainMod, G,exec, $HOME/.local/bin/toggle_layout"
        "$mainMod, W,exec, my-rwall"

        # screenshot
        "$mainMod, S, exec, grimblast --notify --cursor copysave area ~/Pictures/screenshots/$(date +'%Y-%m-%d-At-%Ih%Mm%Ss').png"
        "$mainMod SHIFT, S, exec, kooha"

        # switch focus
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # switch workspace
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"
        "$mainMod, F1, workspace, 11"
        "$mainMod, F2, workspace, 12"
        "$mainMod, F3, workspace, 13"
        "$mainMod, F4, workspace, 14"
        "$mainMod, F5, workspace, 15"
        "$mainMod, F6, workspace, 16"
        "$mainMod, F7, workspace, 17"
        "$mainMod, F8, workspace, 18"
        "$mainMod, F9, workspace, 19"
        "$mainMod, F10, workspace, 20"

        # same as above, but switch to the workspace
        "$mainMod SHIFT, 1, movetoworkspacesilent, 1"
        "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
        "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
        "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
        "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
        "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
        "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
        "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
        "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
        "$mainMod SHIFT, 0, movetoworkspacesilent, 10"
        "$mainMod SHIFT, F1, movetoworkspacesilent, 11"
        "$mainMod SHIFT, F2, movetoworkspacesilent, 12"
        "$mainMod SHIFT, F3, movetoworkspacesilent, 13"
        "$mainMod SHIFT, F4, movetoworkspacesilent, 14"
        "$mainMod SHIFT, F5, movetoworkspacesilent, 15"
        "$mainMod SHIFT, F6, movetoworkspacesilent, 16"
        "$mainMod SHIFT, F7, movetoworkspacesilent, 17"
        "$mainMod SHIFT, F8, movetoworkspacesilent, 18"
        "$mainMod SHIFT, F9, movetoworkspacesilent, 19"
        "$mainMod SHIFT, F10, movetoworkspacesilent, 20"
        "$mainMod CTRL, c, movetoworkspace, emptynm"

        # window control
        "$mainMod SHIFT, left, movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up, movewindow, u"
        "$mainMod SHIFT, down, movewindow, d"
        "$mainMod CTRL, left, resizeactive, -80 0"
        "$mainMod CTRL, right, resizeactive, 80 0"
        "$mainMod CTRL, up, resizeactive, 0 -80"
        "$mainMod CTRL, down, resizeactive, 0 80"
        "$mainMod ALT, left, moveactive,  -80 0"
        "$mainMod ALT, right, moveactive, 80 0"
        "$mainMod ALT, up, moveactive, 0 -80"
        "$mainMod ALT, down, moveactive, 0 80"

        # media and volume controls
        ",XF86AudioRaiseVolume,exec, pamixer -i 2"
        ",XF86AudioLowerVolume,exec, pamixer -d 2"
        ",XF86AudioMute,exec, pamixer -t"
        ",XF86AudioPlay,exec, playerctl play-pause"
        ",XF86AudioNext,exec, playerctl next"
        ",XF86AudioPrev,exec, playerctl previous"
        ",XF86AudioStop, exec, playerctl stop"
        "$mainMod, mouse_down, workspace, e-1"
        "$mainMod, mouse_up, workspace, e+1"

        # desktop brightness
        ",code:233, exec, ddcutil --display `hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | tail -c 3 | sed 's/\\(.\\).$/\\1/'` setvcp 10 + 10"
        ",code:232, exec, ddcutil --display `hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | tail -c 3 | sed 's/\\(.\\).$/\\1/'` setvcp 10 - 10"
        "$mainMod, code:233, exec, ddcutil --display `hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | tail -c 3 | sed 's/\\(.\\).$/\\1/'` setvcp 10 100"
        "$mainMod, code:232, exec, ddcutil --display `hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | tail -c 3 | sed 's/\\(.\\).$/\\1/'` setvcp 10 0"

      ];

      bindl = [
        # laptop brigthness
        ",XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        "$mainMod, XF86MonBrightnessUp, exec, brightnessctl set 100%+"
        "$mainMod, XF86MonBrightnessDown, exec, brightnessctl set 100%-"

        ", switch:Lid Switch, exec, my-sleep"
      ];

      # mouse binding
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      # windowrule
      windowrule = [
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
        "opacity 0.75,nemo"
      ];

      # windowrulev2
      windowrulev2 = [
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
      ];

      workspace = if (host == "laptop") then [
        "r[1-10], monitor:DP-1"
        "r[11-20], monitor:DP-2"
      ] else [
        
      ];

      monitor = if (host == "laptop") then [",preferred,auto,1.9"] else [",preferred,auto,auto"];

      xwayland.force_zero_scaling = true;

    };
  };
}