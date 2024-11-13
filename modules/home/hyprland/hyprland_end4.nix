{ inputs, pkgs, ... }:
let
  hyprland = inputs.hyprland-desktop.packages.${pkgs.system}.hyprland;
  plugins = inputs.hyprland-plugins.packages.${pkgs.system};

  launcher = pkgs.writeShellScriptBin "hypr" ''
    #!/${pkgs.bash}/bin/bash

    export WLR_NO_HARDWARE_CURSORS=1
    export _JAVA_AWT_WM_NONREPARENTING=1

    exec ${hyprland}/bin/Hyprland
  '';
in
{
  home.packages = with pkgs; [
    launcher
    temurin-jre-bin
  ];

  xdg.desktopEntries."org.gnome.Settings" = {
    name = "Settings";
    comment = "Gnome Control Center";
    icon = "org.gnome.Settings";
    exec = "env XDG_CURRENT_DESKTOP=gnome ${pkgs.gnome-control-center}/bin/gnome-control-center";
    categories = [ "X-Preferences" ];
    terminal = false;
  };

  programs = {
    swaylock = {
      enable = true;
      # package = pkgs.swaylock-effects;
    };
  };

  wayland.windowManager.hyprland = {
    settings = {
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
      misc = {
        vfr = 1;
        vrr = 1;
        # layers_hog_mouse_focus = true;
        focus_on_activate = true;
        animate_manual_resizes = false;
        animate_mouse_windowdragging = false;
        enable_swallow = false;
        swallow_regex = "(foot|kitty|allacritty|Alacritty)";

        disable_hyprland_logo = true;
        new_window_takes_over_fullscreen = 2;
      };
      debug = {
        # overlay = true;
        # damage_tracking = 0;
        # damage_blink = true;
      };
      bind =
        let SLURP_COMMAND = "$(slurp -d -c eedcf5BB -b 4f425644 -s 00000000)";
        in [
          "Super, C, exec, code --password-store=gnome"
          "Super, T, exec, kitty"
          "Super, E, exec, nemo"
          "Super+Alt, E, exec, thunar"
          "Super, W, exec, firefox"
          "Control+Super, W, exec, thorium-browser --ozone-platform-hint=wayland --gtk-version=4 --ignore-gpu-blocklist --enable-features=TouchpadOverscrollHistoryNavigation"
          "Super, X, exec, gnome-text-editor --new-window"
          "Super+Shift, W, exec, wps"
          ''Super, I, exec, XDG_CURRENT_DESKTOP="gnome" gnome-control-center''
          "Control+Super, V, exec, pavucontrol"
          "Control+Shift, Escape, exec, gnome-system-monitor"
          "Super, Period, exec, pkill fuzzel || ~/.local/bin/fuzzel-emoji"
          "Super, Q, killactive, "
          "Super+Alt, Space, togglefloating, "
          "Shift+Super+Alt, Q, exec, hyprctl kill"
          "Control+Shift+Alt, Delete, exec, pkill wlogout || wlogout -p layer-shell"
          "Control+Shift+Alt+Super, Delete, exec, systemctl poweroff"
          ''
            Super+Shift+Alt, S, exec, grim -g "${SLURP_COMMAND}" - | swappy -f -
          ''
          ''
            Super+Shift, S, exec, grim -g "${SLURP_COMMAND}" - | wl-copy
          ''
          "Super+Alt, R, exec, ~/.config/ags/scripts/record-script.sh"
          "Control+Alt, R, exec, ~/.config/ags/scripts/record-script.sh --fullscreen"
          "Super+Shift+Alt, R, exec, ~/.config/ags/scripts/record-script.sh --fullscreen-sound"
          "Super+Shift, C, exec, hyprpicker -a"
          "Super, V, exec, pkill fuzzel || cliphist list | fuzzel --no-fuzzy --dmenu | cliphist decode | wl-copy"
          ''
            Control+Super+Shift,S,exec,grim -g "${SLURP_COMMAND}" "tmp.png" && tesseract "tmp.png" - | wl-copy && rm "tmp.png"
          ''
          "Super, L, exec, swaylock"
          "Super+Shift, L, exec, swaylock"
          "Control+Super, Slash, exec, pkill anyrun || anyrun"
          "Control+Super, T, exec, ~/.config/ags/scripts/color_generation/switchwall.sh"
          "Control+Super, R, exec, killall ags ydotool; ags -b hypr"
          "Super, Tab, exec, ags -t 'overview'"
          "Super, Slash, exec, ags -t 'cheatsheet'"
          "Super, B, exec, ags -t 'sideleft'"
          "Super, A, exec, ags -t 'sideleft'"
          "Super, O, exec, ags -t 'sideleft'"
          "Super, N, exec, ags -t 'sideright'"
          "Super, M, exec, ags run-js 'openMusicControls.value = !openMusicControls.value;'"
          "Super, Comma, exec, ags run-js 'openColorScheme.value = true; Utils.timeout(2000, () => openColorScheme.value = false);'"
          "Super, K, exec, ags -t 'osk'"
          "Control+Alt, Delete, exec, ags -t 'session'"
          "Super+Alt, f12, exec, notify-send 'Test notification' 'This is a really long message to test truncation and wrapping\\nYou can middle click or flick this notification to dismiss it!' -a 'Shell' -A 'Test1=I got it!' -A 'Test2=Another action'"
          "Super+Alt, Equal, exec, notify-send 'Urgent notification' 'Ah hell no' -u critical -a 'Hyprland keybind'"
          "Super+Shift, left, movewindow, l"
          "Super+Shift, right, movewindow, r"
          "Super+Shift, up, movewindow, u"
          "Super+Shift, down, movewindow, d"
          "Super, left, movefocus, l"
          "Super, right, movefocus, r"
          "Super, up, movefocus, u"
          "Super, down, movefocus, d"
          "Super, BracketLeft, movefocus, l"
          "Super, BracketRight, movefocus, r"
          "Control+Super, right, workspace, +1"
          "Control+Super, left, workspace, -1"
          "Control+Super, BracketLeft, workspace, -1"
          "Control+Super, BracketRight, workspace, +1"
          "Control+Super, up, workspace, -5"
          "Control+Super, down, workspace, +5"
          "Super, Page_Down, workspace, +1"
          "Super, Page_Up, workspace, -1"
          "Control+Super, Page_Down, workspace, +1"
          "Control+Super, Page_Up, workspace, -1"
          "Super+Alt, Page_Down, movetoworkspace, +1"
          "Super+Alt, Page_Up, movetoworkspace, -1"
          "Super+Shift, Page_Down, movetoworkspace, +1"
          "Super+Shift, Page_Up, movetoworkspace, -1"
          "Control+Super+Shift, Right, movetoworkspace, +1"
          "Control+Super+Shift, Left, movetoworkspace, -1"
          "Super+Shift, mouse_down, movetoworkspace, -1"
          "Super+Shift, mouse_up, movetoworkspace, +1"
          "Super+Alt, mouse_down, movetoworkspace, -1"
          "Super+Alt, mouse_up, movetoworkspace, +1"
          "Super, F, fullscreen, 0"
          "Super, D, fullscreen, 1"
          # "Super_Alt, F, fakefullscreen, 0"
          "Super, 1, workspace, 1"
          "Super, 2, workspace, 2"
          "Super, 3, workspace, 3"
          "Super, 4, workspace, 4"
          "Super, 5, workspace, 5"
          "Super, 6, workspace, 6"
          "Super, 7, workspace, 7"
          "Super, 8, workspace, 8"
          "Super, 9, workspace, 9"
          "Super, 0, workspace, 10"
          "Super, S, togglespecialworkspace,"
          "Control+Super, S, togglespecialworkspace,"
          "Alt, Tab, cyclenext"
          "Alt, Tab, bringactivetotop,"
          "Super+Alt, 1, movetoworkspacesilent, 1"
          "Super+Alt, 2, movetoworkspacesilent, 2"
          "Super+Alt, 3, movetoworkspacesilent, 3"
          "Super+Alt, 4, movetoworkspacesilent, 4"
          "Super+Alt, 5, movetoworkspacesilent, 5"
          "Super+Alt, 6, movetoworkspacesilent, 6"
          "Super+Alt, 7, movetoworkspacesilent, 7"
          "Super+Alt, 8, movetoworkspacesilent, 8"
          "Super+Alt, 9, movetoworkspacesilent, 9"
          "Super+Alt, 0, movetoworkspacesilent, 10"
          "Control+Shift+Super, Up, movetoworkspacesilent, special"
          "Super+Alt, S, movetoworkspacesilent, special"
          "Super, mouse_up, workspace, +1"
          "Super, mouse_down, workspace, -1"
          "Control+Super, mouse_up, workspace, +1"
          "bind = Control+Super, mouse_down, workspace, -1"
        ];
      bindm = [
        "Super, mouse:272, movewindow"
        "Super, mouse:273, resizewindow"
        "Super, Z, movewindow"
      ];
      bindl = [
        ",XF86AudioMute, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 0%"
        "Super+Shift,M, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 0%"
        ",Print,exec,grim - | wl-copy"
        ''
          Super+Shift, N, exec, playerctl next || playerctl position `bc <<< "100 * $(playerctl metadata mpris:length) / 1000000 / 100"`''
        ''
          ,XF86AudioNext, exec, playerctl next || playerctl position `bc <<< "100 * $(playerctl metadata mpris:length) / 1000000 / 100"`''
        "Super+Shift, B, exec, playerctl previous"
        "Super+Shift, P, exec, playerctl play-pause"
        ",XF86AudioPlay, exec, playerctl play-pause"
        "Super+Shift, L, exec, sleep 0.1 && systemctl suspend"
        ", XF86AudioMute, exec, ags run-js 'indicator.popup(1);'"
        "Super+Shift,M,   exec, ags run-js 'indicator.popup(1);'"
      ];
      bindle = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86MonBrightnessUp, exec, ags run-js 'brightness.screen_value += 0.05;indicator.popup(1);'"
        ",XF86MonBrightnessDown, exec, ags run-js 'brightness.screen_value -= 0.05;indicator.popup(1);'"
        # ",XF86AudioRaiseVolume, exec, ags run-js 'indicator.popup(1);'"
        # ",XF86AudioLowerVolume, exec, ags run-js 'indicator.popup(1);'"
        ",XF86MonBrightnessUp, exec, ags run-js 'indicator.popup(1);'"
        ",XF86MonBrightnessDown, exec, ags run-js 'indicator.popup(1);'"
        "Alt, I, exec, ydotool key 103:1 103:0 "
        "Alt, K, exec, ydotool key 108:1 108:0"
        "Alt, J, exec, ydotool key 105:1 105:0"
        "Alt, L, exec, ydotool key 106:1 106:0"
      ];
      bindr = [
        "Control+Super, R, exec, killall ags .ags-wrapped ydotool; ags &"
        "Control+Super+Alt, R, exec, hyprctl reload; killall ags ydotool; ags &"
      ];
      bindir = [ "Super, Super_L, exec, ags -t 'overview'" ];
      binde = [
        "Super, Minus, splitratio, -0.1"
        "Super, Equal, splitratio, 0.1"
        "Super, Semicolon, splitratio, -0.1"
        "Super, Apostrophe, splitratio, 0.1"
      ];
      windowrule = [
        "noblur,.*" # Disables blur for windows. Substantially improves performance.
        "float, ^(steam)$"
        "pin, ^(showmethekey-gtk)$"
        "float,title:^(Open File)(.*)$"
        "float,title:^(Select a File)(.*)$"
        "float,title:^(Choose wallpaper)(.*)$"
        "float,title:^(Open Folder)(.*)$"
        "float,title:^(Save As)(.*)$"
        "float,title:^(Library)(.*)$ "
      ];
      windowrulev2 = [ "tile,class:(wpsoffice)" ];
      layerrule = [
        "xray 1, .*"
        "noanim, selection"
        "noanim, overview"
        "noanim, anyrun"
        "blur, swaylock"
        "blur, eww"
        "ignorealpha 0.8, eww"
        "noanim, noanim"
        "blur, noanim"
        "blur, gtk-layer-shell"
        "ignorezero, gtk-layer-shell"
        "blur, launcher"
        "ignorealpha 0.5, launcher"
        "blur, notifications"
        "ignorealpha 0.69, notifications"
        "blur, session"
        "noanim, sideright"
        "noanim, sideleft"
      ];
    };
  };
}