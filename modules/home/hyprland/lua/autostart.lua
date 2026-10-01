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
if IS_HIGH_POWER then
  hl.on("hyprland.start", function()
    hl.exec_cmd("my-rwall -n nixos.png")
    hl.exec_cmd("openrgb --startminimized -b 0 -m direct")

    -- Desktop default workspace setup
    --
    -- Two Lua-era changes from the hyprlang version:
    --  * `hyprctl dispatch focusmonitor/workspace ...` no longer exists:
    --    hyprctl dispatch now takes a Lua expression. Inside the config we just
    --    call hl.dispatch(hl.dsp.focus(...)) directly.
    --  * The "[workspace 1 silent] cmd" prefix is hyprlang exec syntax. In Lua
    --    the rules go in a table: hl.exec_cmd(cmd, { workspace = "1 silent" }).
    --    (They're matched to the spawned window by PID, so if an app forks and
    --    the real window lands on the wrong workspace, add a hl.window_rule for
    --    it instead.)
    hl.dispatch(hl.dsp.focus({ monitor = "DP-1" }))
    hl.exec_cmd('kitty --hold sh -ic "cd ~/nixos-config && git pull && nvim"', { workspace = "1 silent" })
    hl.exec_cmd('vivaldi --profile-directory="Default"', { workspace = "2 silent" })
    hl.exec_cmd('vivaldi --profile-directory="Profile 1"', { workspace = "3 silent" })
    hl.exec_cmd("thunderbird", { workspace = "4 silent" })

    hl.dispatch(hl.dsp.focus({ monitor = "HDMI-A-1" }))
    hl.exec_cmd('vivaldi --profile-directory="Default"', { workspace = "11 silent" })
    hl.exec_cmd("kitty", { workspace = "12 silent" })
    hl.exec_cmd("beefweb_mpris", { workspace = "13 silent" })
    hl.exec_cmd("beeper", { workspace = "14 silent" })

    hl.dispatch(hl.dsp.focus({ workspace = 1 }))
    hl.dispatch(hl.dsp.focus({ monitor = "DP-1" }))
  end)
end

-- Laptop-only startup commands
if IS_LAPTOP then
  hl.on("hyprland.start", function()
    hl.exec_cmd("poweralertd")
  end)
end
