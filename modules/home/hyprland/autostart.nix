{ isHighPower, isLaptop, lib, ... } : {
  wayland.windowManager.hyprland.settings = {

    # Autostart
    exec-once = [
      # Setting variables globally
      "systemctl --user import-environment"
      "systemctl --user start hyprpolkitagent"
      "dbus-update-activation-environment --systemd"
      "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

      # Set startup apps
      "pidof hyprlock || hyprlock"
      "hyprsunset"
      "sleep 1 && waybar"
      "nm-applet"
      "blueman-applet"
      "elephant"
      "walker --gapplication-service"
      "wl-clip-persist --clipboard regular"
      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"
      # "wl-copy" # Might clear the clipboard history on boot
      "cd ~/nixos-config && git fetch"
    ] ++ lib.optionals isHighPower [
      "my-rwall -n nixos.png"
      "openrgb --startminimized -b 0 -m direct"
      "sunshine"
      "beeper"

      # Opening programs by default (not needed, just nice)
      # Main Monitor
      "hyprctl dispatch focusmonitor DP-1"
      "hyprctl dispatch exec '[workspace 2 silent] vivaldi --profile-directory=\"Profile 1\"'"
      "cd ~/nixos-config && hyprctl dispatch exec '[workspace 1 silent] nvim'"

      # Secondary Monitor
      "hyprctl dispatch focusmonitor HDMI-A-1"
      "hyprctl dispatch exec '[workspace 11 silent] vivaldi --profile-directory=\"Default\"'"
      "hyprctl dispatch exec '[workspace 13 silent] beefweb_mpris'"
      "hyprctl dispatch exec '[workspace 12 silent] kitty'"

      # Change focus back to main
      "hyprctl dispatch workspace 1"
      "hyprctl dispatch focusmonitor DP-1"
      
    ] ++ lib.optionals isLaptop [
      "poweralertd"
    ];
  };
}
