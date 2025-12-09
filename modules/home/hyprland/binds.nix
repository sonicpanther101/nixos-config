{ host, ... } : {
  wayland.windowManager.hyprland.settings = {

    bind = [
      # keybindings

      # terminal
      "SUPER, Return, exec, kitty"
      "ALT, Return, exec, kitty --title float_kitty"
      "SUPER SHIFT, Return, exec, kitty --start-as=fullscreen -o 'font_size=16'"

      # Browser
      "SUPER, B, exec, vivaldi --profile-directory=\"Default\" --allowlisted-extension-id=clngdbkpkpeebahjckkjfobafhncgmne"
      # School Profile
      "SUPER SHIFT, B, exec, vivaldi --profile-directory=\"Profile 1\""

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
      "SUPER, S, exec, grimblast --notify copysave area ~/Pictures/screenshots/$(date +'%Y-%m-%d-At-%Ih%Mm%Ss').png"
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
      "SUPER, Escape, exec, pidof hyprlock || hyprlock"
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
  };
}