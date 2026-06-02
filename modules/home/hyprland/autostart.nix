{ isHighPower, isLaptop, lib, ... } : {
  wayland.windowManager.hyprland.settings = {

    # Autostart
    exec-once = [
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
      "blueman-applet"
      "pidof hyprlock || hyprlock"
      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"
      # "wl-copy" # Might clear the clipboard history on boot
      "cd ~/nixos-config && git fetch"
    ] ++ lib.optionals isHighPower [
      "my-rwall -n nixos.png"
      "openrgb --startminimized -b 0 -m direct"
      "sunshine"

      # Opening programs by default (not needed, just nice)
      # Main Monitor
      "hyprctl dispatch focusmonitor DP-1"
      "hyprctl dispatch exec '[workspace 1 silent] vivaldi --profile-directory=\"Default\"'"

      # Secondary Monitor
      "hyprctl dispatch focusmonitor HDMI-A-1"
      "hyprctl dispatch exec '[workspace 11 silent] beefweb_mpris'"
      "hyprctl dispatch exec '[workspace 12 silent] codium'"
      "hyprctl dispatch exec '[workspace 13 silent] kitty'"

      # Change focus back to main
      "hyprctl dispatch workspace 1"
      "hyprctl dispatch focusmonitor DP-1"
      
    ] ++ lib.optionals isLaptop [
      "poweralertd"
    ];
  };
}