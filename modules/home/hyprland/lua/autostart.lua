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
    -- NOTE: previously these wrapped the command as
    -- hl.exec_cmd('hyprctl dispatch exec "...\"...\"..."'), which reused the
    -- same " character for both the outer hyprctl-arg quoting and the inner
    -- sh -ic quoting. Once the inner \" closed early, the trailing
    -- "&& git pull && nvim" fell OUTSIDE any quoting and was interpreted by
    -- the shell as separate && commands instead of staying inside kitty's
    -- sh -ic string - so kitty launched with a broken arg and git
    -- pull/nvim silently ran detached instead of inside the terminal.
    -- hl.exec_cmd() is already the exec dispatcher (it supports the
    -- "[workspace N silent]" rule prefix directly - see the Dispatchers
    -- wiki page), so there's no need to shell out through
    -- "hyprctl dispatch exec" at all. Using Lua's [[ ]] long-bracket
    -- strings means the embedded " characters need no escaping, so there's
    -- no quote-nesting to get wrong.
    hl.exec_cmd([[[workspace 1 silent] kitty --hold sh -ic "cd ~/nixos-config && git pull && nvim"]])
    hl.exec_cmd([[[workspace 2 silent] vivaldi --profile-directory="Default"]])
    hl.exec_cmd([[[workspace 3 silent] vivaldi --profile-directory="Profile 1"]])
    hl.exec_cmd([[[workspace 4 silent] thunderbird]])

    hl.exec_cmd([[[workspace 12 silent] kitty]])
    hl.exec_cmd([[[workspace 13 silent] beefweb_mpris]])
    hl.exec_cmd([[[workspace 14 silent] beeper]])

    hl.dsp.focus({ workspace = 1 })
  end)
end

-- Laptop-only startup commands
if IS_LAPTOP then
  hl.on("hyprland.start", function()
    hl.exec_cmd("poweralertd")
  end)
end
