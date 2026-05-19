{ ... } : {
wayland.windowManager.hyprland.extraConfig =
  let
    # Bind helpers — each generates a hl.bind() call
    bind  = key: action:        ''hl.bind("${key}", ${action})'';
    bindl = key: action:        ''hl.bind("${key}", ${action}, { locked = true })'';
    binde = key: action:        ''hl.bind("${key}", ${action}, { repeating = true })'';
    bindm = key: action:        ''hl.bind("${key}", ${action}, { mouse = true })'';
    bindlr = key: action:       ''hl.bind("${key}", ${action}, { locked = true, repeating = true })'';

    # Dispatcher helpers
    exec   = cmd: ''hl.dsp.exec_cmd("${cmd}")'';
    # For dispatchers not yet in the Lua API, fall back to hyprctl
    hctl   = dispatcher: args: ''hl.dsp.exec_cmd("hyprctl dispatch ${dispatcher} ${args}")'';

    lines = builtins.concatStringsSep "\n";
  in
    lines [
      # Terminal
      (bind "SUPER + Return" (exec "kitty"))
      (bind "ALT + Return" (exec "kitty --title float_kitty"))
      (bind "SUPER + SHIFT + Return" (exec "kitty --start-as=fullscreen -o 'font_size=16'"))

      # Browser
      (bind "SUPER + B" (exec "vivaldi --profile-directory=\\\"Default\\\" --allowlisted-extension-id=clngdbkpkpeebahjckkjfobafhncgmne"))
      # School Profile
      (bind "SUPER + SHIFT + B" (exec "vivaldi --profile-directory=\\\"Profile 1\\\""))

      # File browser
      (bind "SUPER + E" (exec "nemo"))
      (bind "SUPER + SHIFT + E" (exec "nemo --name=float_nemo"))

      # Launchers
      (bind "SUPER + R" (exec "wofi --show drun"))
      # (bind "SUPER + R" (exec "my-ags"))
      (bind "SUPER + SHIFT + R" (exec "my-ags -l"))
      (bind "SUPER + D" (exec "ags toggle app-launcher"))
      (bind "ALT + V" (exec "copyq show"))
      # (bind "ALT + V" (exec "ags toggle clipboard"))
      (bind "SUPER + G" (exec "ags toggle apis"))
      (bind "SUPER + W" (exec "ags toggle wallpaper"))
      (bind "SUPER + SHIFT + W" (exec "ags toggle mouse-helper"))
      (bind "SUPER + F1" (exec "show-keybinds"))
      (bind "SUPER + SHIFT + F8" (exec "sh -c 'pkill waybar; waybar'"))

      # Vscodium
      (bind "SUPER + V" (exec "codium"))
      (bind "SUPER + SHIFT + V" (exec "codium ~/nixos-config"))
      (bind "SUPER + SHIFT + CTRL + V" (exec "codium ~/nixos-config/modules/home/ags/ags"))

      # Misc
      (bind "SUPER + C" (exec "hyprpicker -a"))
      (bind "SUPER + period" (exec "wofi-emoji"))

      # Screenshot
      (bind "SUPER + S" (exec "grimblast --notify copysave area ~/Pictures/screenshots/$(date +'%Y-%m-%d-At-%Hh%Mm%Ss').png"))
      (bind "SUPER + SHIFT + S" (exec "kooha"))

      # Focus
      (bind "SUPER + left" (exec "focus-move l"))
      (bind "SUPER + right" (exec "focus-move r"))
      (bind "SUPER + up" "hl.dsp.focus({ direction = 'up' })")
      (bind "SUPER + down" "hl.dsp.focus({ direction = 'down' })")

      (bind "SUPER + CTRL + c" "hl.dsp.window.move({ workspace = 'emptynm' })")

      # Window controls
      (bind "SUPER + Q" "hl.dsp.window.close()")
      (bind "SUPER + F" "hl.dsp.window.fullscreen({ mode = 0 })")
      (bind "SUPER + Space" "hl.dsp.window.float({ action = 'toggle' })")
      (bind "SUPER + J" "hl.dsp.layout('togglesplit')")
      (bind "ALT + Tab" "hl.dsp.focus({ last = true })")

      # Move windows
      (bind  "SUPER + SHIFT + left"  (hctl "movewindow" "l"))
      (bind  "SUPER + SHIFT + right" (hctl "movewindow" "r"))
      (bind  "SUPER + SHIFT + up"    (hctl "movewindow" "u"))
      (bind  "SUPER + SHIFT + down"  (hctl "movewindow" "d"))

      # Resize windows
      (binde "SUPER + CTRL + left"   (hctl "resizeactive" "-80 0"))
      (binde "SUPER + CTRL + right"  (hctl "resizeactive" "80 0"))
      (binde "SUPER + CTRL + up"     (hctl "resizeactive" "0 -80"))
      (binde "SUPER + CTRL + down"   (hctl "resizeactive" "0 80"))

      # Move floating windows
      (bind  "SUPER + ALT + left"    (hctl "moveactive" "-80 0"))
      (bind  "SUPER + ALT + right"   (hctl "moveactive" "80 0"))
      (bind  "SUPER + ALT + up"      (hctl "moveactive" "0 -80"))
      (bind  "SUPER + ALT + down"    (hctl "moveactive" "0 80"))

      # Workspace switching (hyprsome)
      ''
        local smw = hl.plugin.split_monitor_workspaces
        for i = 1, 10 do
          local key = tostring(i%10)
          hl.bind("SUPER + " .. key, function() return smw.workspace(i) end)
          hl.bind("SUPER + SHIFT + " .. key, function() return smw.move_to_workspace_silent(i) end)
        end
      ''
      
      # Workspace scroll
      (bind "SUPER + mouse_up" "function() return smw.cycle_workspaces(1) end")
      (bind "SUPER + mouse_down" "function() return smw.cycle_workspaces(-1) end")
      (bind "SUPER + Tab" "function() return smw.cycle_workspaces(1) end")
      (bind "SUPER + SHIFT + Tab" "function() return smw.cycle_workspaces(-1) end")

      # Locked binds (work on lockscreen)

      # Laptop brightness
      (bindlr "XF86MonBrightnessUp" (exec "brightnessctl set 5%+"))
      (bindlr "XF86MonBrightnessDown" (exec "brightnessctl set 5%-"))
      (bindl "SUPER + XF86MonBrightnessUp" (exec "brightnessctl set 100%+"))
      (bindl "SUPER + XF86MonBrightnessDown" (exec "brightnessctl set 100%-"))

      # Desktop brightness
      (bindlr "code:233" (exec "ddcutil --display `hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | grep -q DP && echo 2 || echo 1` setvcp 10 + 10"))
      (bindlr "code:232" (exec "ddcutil --display `hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | grep -q DP && echo 2 || echo 1` setvcp 10 - 10"))
      (bindl "SUPER + code:233" (exec "ddcutil --display `hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | grep -q DP && echo 2 || echo 1` setvcp 10 100"))
      (bindl "SUPER + code:232" (exec "ddcutil --display `hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | grep -q DP && echo 2 || echo 1` setvcp 10 0"))

      # Shutdown options
      (bindl "SUPER + Escape" (exec "pidof hyprlock || hyprlock"))
      (bindl "SUPER + SHIFT + Escape" (exec "my-sleep"))
      (bindl "SUPER + SHIFT + CTRL + Escape" (exec "hyprshutdown -t 'Shutting down...' --post-cmd 'my-shutdown'"))
      (bindl "SUPER + SHIFT + CTRL + ALT + Escape" (exec "hyprshutdown -t 'Restarting...' --post-cmd 'reboot'"))
      (bindl "switch:Lid Switch" (exec "my-sleep"))

      # Media and volume controls
      (bindlr "XF86AudioRaiseVolume" (exec "pamixer -i 2"))
      (bindlr "XF86AudioLowerVolume" (exec "pamixer -d 2"))
      (bindl "XF86AudioMute" (exec "pamixer -t"))
      (bindl "XF86AudioPlay" (exec "playerctl play-pause"))
      (bindl "XF86AudioNext" (exec "playerctl next"))
      (bindl "XF86AudioPrev" (exec "playerctl previous"))
      (bindl "XF86AudioStop" (exec "playerctl stop"))

      # Mouse binds
      (bindm "SUPER + mouse:272" "hl.dsp.window.drag()")
      (bindm "SUPER + mouse:273" "hl.dsp.window.resize()")

      # Gesture
      ''hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })''
  ];
}