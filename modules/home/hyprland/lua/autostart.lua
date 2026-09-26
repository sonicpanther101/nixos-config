-- Autostart commands migrated from modules/home/hyprland/autostart.nix
-- Symlinked to ~/.config/hypr/autostart.lua at activation
-- Changes trigger hyprctl reload only (no Nix rebuild needed)

-- Always-run startup commands
hl.on("hyprland.start", function()
  -- Environment setup
  hl.exec_cmd("systemctl --user import-environment")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("dbus-update-activation-environment --systemd")
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

  -- Lock screen and utilities
  hl.exec_cmd("systemctl --user start hyprlock.service")
  hl.exec_cmd("hyprsunset")
  hl.exec_cmd("nm-applet")
  hl.exec_cmd("blueman-applet")
  hl.exec_cmd("wl-clip-persist --clipboard regular")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")

  -- Git fetch
  hl.exec_cmd("cd ~/nixos-config && git fetch")
end)

-- High-power startup commands (desktop + high-power laptop)
if os.getenv("IS_HIGH_POWER") == "1" then
  hl.on("hyprland.start", function()
    hl.exec_cmd("my-rwall -n nixos.png")
    hl.exec_cmd("openrgb --startminimized -b 0 -m direct")

    -- Desktop default workspace setup
    hl.exec_cmd("hyprctl dispatch focusmonitor DP-1")
    hl.exec_cmd('hyprctl dispatch exec "[workspace 1 silent] kitty --hold sh -ic \"cd ~/nixos-config && git pull && nvim\""')
    hl.exec_cmd('hyprctl dispatch exec "[workspace 2 silent] vivaldi --profile-directory=\"Default\""')
    hl.exec_cmd('hyprctl dispatch exec "[workspace 3 silent] vivaldi --profile-directory=\"Profile 1\""')
    hl.exec_cmd('hyprctl dispatch exec "[workspace 4 silent] thunderbird"')

    hl.exec_cmd("hyprctl dispatch focusmonitor HDMI-A-1")
    hl.exec_cmd('hyprctl dispatch exec "[workspace 11 silent] vivaldi --profile-directory=\"Default\""')
    hl.exec_cmd('hyprctl dispatch exec "[workspace 12 silent] kitty"')
    hl.exec_cmd('hyprctl dispatch exec "[workspace 13 silent] beefweb_mpris"')
    hl.exec_cmd('hyprctl dispatch exec "[workspace 14 silent] beeper"')

    hl.exec_cmd("hyprctl dispatch workspace 1")
    hl.exec_cmd("hyprctl dispatch focusmonitor DP-1")
  end)
end

-- Laptop-only startup commands
if os.getenv("IS_LAPTOP") == "1" then
  hl.on("hyprland.start", function()
    hl.exec_cmd("poweralertd")
  end)
end
