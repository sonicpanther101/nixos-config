{ host, ... } : {
wayland.windowManager.hyprland.extraConfig = 
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
      "hyprctl dispatch 'hl.dsp.exec_cmd(\"vivaldi --profile-directory=\\\"Default\\\"\")'"

      # Secondary Monitor
      "hyprctl dispatch 'hl.dsp.focus({ monitor = \"HDMI-A-1\" })'"
      "hyprctl dispatch 'hl.dsp.exec_cmd(\"beefweb_mpris\")'"
      "hyprctl dispatch 'hl.dsp.exec_cmd(\"codium\")'"
      "hyprctl dispatch 'hl.dsp.exec_cmd(\"kitty\")'"

      # Change focus back to main
      "hyprctl dispatch 'hl.dsp.focus({ monitor = \"DP-1\" })'"
      "hyprctl dispatch 'hl.dsp.focus({ workspace = 11 })'"

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
}