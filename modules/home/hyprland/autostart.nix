{ host, ... } : {
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
      "sleep 1 && pidof swaylock || swaylock"
      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"
      # "wl-copy" # Might clear the clipboard history on boot
      "cd ~/nixos-config && git fetch"
    ]++ (if (host == "desktop") then [
      "openrgb --startminimized -b 0 -m direct"

      # Opening programs by default (not needed, just nice)
      # Secondary Monitor
      "hyprctl dispatch focusmonitor HDMI-A-1"
      "hyprctl dispatch exec '[workspace 1 silent] vivaldi --profile-directory=\"Default\"'"
      "hyprctl dispatch exec '[workspace 2 silent] Grayjay'"

      # Main Monitor
      "hyprctl dispatch focusmonitor DP-1"
      "hyprctl dispatch workspace 11 && hyprctl dispatch exec '[workspace 11 silent] beefweb_mpris'"
      "hyprctl dispatch workspace 12 && hyprctl dispatch exec '[workspace 12 silent] codium'"
      "hyprctl dispatch workspace 13 && hyprctl dispatch exec '[workspace 13 silent] kitty'"

      # Change focus back to secondary
      "hyprctl dispatch workspace 11"
      "hyprctl dispatch focusmonitor HDMI-A-1"

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
  };
}