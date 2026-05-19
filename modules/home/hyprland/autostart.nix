{ host, ... } : {
  wayland.windowManager.hyprland.settings = {

    # Autostart
    extraConfig = 
      let
        shared = [
          # Setting variables globally
          "systemctl --user import-environment"
          "systemctl --user start hyprpolkitagent"
          "dbus-update-activation-environment --systemd"
          "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

          # To be changed
          "sleep 1 && waybar"
          "copyq"

          # Set startup apps
          "hyprsunset"
          "nm-applet"
          "pidof hyprlock || hyprlock"
          "wl-paste --type text --watch cliphist store"
          "wl-paste --type image --watch cliphist store"
          # "wl-copy" # Might clear the clipboard history on boot
          "cd ~/nixos-config && git fetch"
        ];
        desktop = [
          "awww-daemon"
          "openrgb --startminimized -b 0 -m direct"

          # Opening programs by default (not needed, just nice)
          # Main Monitor
          "hyprctl dispatch focusmonitor DP-1"
          "hyprctl dispatch exec '[workspace 11 silent] vivaldi --profile-directory=\"Default\"'"

          # Secondary Monitor
          "hyprctl dispatch focusmonitor HDMI-A-1"
          "hyprctl dispatch workspace 1 && hyprctl dispatch exec '[workspace 1 silent] beefweb_mpris'"
          "hyprctl dispatch workspace 2 && hyprctl dispatch exec '[workspace 2 silent] codium'"
          "hyprctl dispatch workspace 3 && hyprctl dispatch exec '[workspace 3 silent] kitty'"

          # Change focus back to main
          "hyprctl dispatch workspace 1"
          "hyprctl dispatch focusmonitor DP-1"

          "imv ~/Pictures/system/Study\ times.png"

        ];
        laptops = [
          "poweralertd"
        ];
        allCmds = shared ++ (if host == "desktop" then desktop else laptops);
        mkExecCmd = cmd: ''hl.exec_cmd("${cmd}")'';
      in ''
        hl.on("hyprland.start", function()
          ${builtins.concatStringsSep "\n  " (map mkExecCmd allCmds)}
        end)
      '';
  };
}