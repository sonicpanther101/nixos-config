-- Keybinds migrated from modules/home/hyprland/keybinds.nix
-- Symlinked to ~/.config/hypr/keybinds.lua at activation
-- Changes trigger hyprctl reload only (no Nix rebuild needed)
--
-- NOTE: keys are joined with "+" (Hyprland 0.55+ Lua bind syntax), not the
-- old hyprlang "MODS, key" comma syntax. Dispatchers live under hl.dsp.window.*
-- for anything that acts on the active/a window; a few (exec_cmd, layout,
-- focus) stay top-level under hl.dsp.*. There is no hl.dsp.movetoworkspace,
-- hl.dsp.killactive, hl.dsp.fullscreen, hl.dsp.togglefloating, hl.dsp.layoutmsg,
-- hl.dsp.cyclenext, hl.dsp.bringactivetotop, hl.dsp.movewindow,
-- hl.dsp.resizeactive or hl.dsp.moveactive - those are hyprlang-era names that
-- don't exist in the Lua API and would all nil-crash the same way
-- hl.dsp.movetoworkspace did (see docs: https://alejandrominaya.github.io/hyprland-lua-docs/).

-- split-monitor-workspaces exposes its Lua API via require(); package.loaded
-- already has it cached from hyprland.lua's initial require+setup(), so this
-- just fetches the same table (cheap, doesn't re-run setup()).
local smw = require("plugins.split-monitor-workspaces")

-- Terminal
hl.bind("SUPER+Return", hl.dsp.exec_cmd("kitty"))
hl.bind("ALT+Return", hl.dsp.exec_cmd("kitty --title float_kitty"))
hl.bind("SUPER+SHIFT+Return", hl.dsp.exec_cmd('kitty --start-as=fullscreen -o "font_size=16"'))

-- Browser
hl.bind("SUPER+B", hl.dsp.exec_cmd('vivaldi --profile-directory="Default" --allowlisted-extension-id=clngdbkpkpeebahjckkjfobafhncgmne'))
hl.bind("SUPER+SHIFT+B", hl.dsp.exec_cmd('vivaldi --profile-directory="Profile 1"'))

-- File browser
hl.bind("SUPER+E", hl.dsp.exec_cmd("nemo"))
hl.bind("ALT+E", hl.dsp.exec_cmd("nemo --name=float_nemo"))

-- Note taking
hl.bind("SUPER+N", hl.dsp.exec_cmd("xournalpp"))
hl.bind("SUPER+ALT+N", hl.dsp.exec_cmd("sleep 2 && wlrctl pointer move 1 1 || true"))

-- Misc
hl.bind("SUPER+R", hl.dsp.exec_cmd("walker"))
hl.bind("ALT+V", hl.dsp.exec_cmd("walker -m clipboard"))
hl.bind("SUPER+period", hl.dsp.exec_cmd("walker -m symbols"))
hl.bind("SUPER+W", hl.dsp.exec_cmd("walker -m menus:wallpapers"))
hl.bind("SUPER+F1", hl.dsp.exec_cmd("walker -m menus:keybinds"))
hl.bind("SUPER+F2", hl.dsp.exec_cmd("walker -m menus:aliases"))
hl.bind("SUPER+ALT+W", hl.dsp.exec_cmd("systemctl --user restart waybar.service"))
hl.bind("SUPER+ALT+K", hl.dsp.exec_cmd("my-toggle-keyboard"))
hl.bind("SUPER+ALT+P", hl.dsp.exec_cmd("beefweb_mpris"))
hl.bind("SUPER+C", hl.dsp.exec_cmd("hyprpicker -a"))

-- Submap entry. Dispatchers only *describe* an action, so this must be handed
-- straight to hl.bind (a function body that merely builds one does nothing).
hl.bind("SUPER+M", hl.dsp.submap("monitor"))

-- "monitor" submap: D = toggle dpms on the focused monitor (movies),
-- I = toggle colour invert (darkness). Each performs its action then drops back
-- to the normal keymap, so it feels like a SUPER+M, SUPER+D chord.
hl.define_submap("monitor", function()
  hl.bind("SUPER+D", function()
    local mon = hl.get_active_monitor()
    hl.dispatch(hl.dsp.dpms({ action = "toggle", monitor = mon and mon.name or nil }))
    hl.dispatch(hl.dsp.submap("reset"))
  end)

  hl.bind("SUPER+I", function()
    hl.dispatch(hl.dsp.exec_cmd("my-invert-monitor"))
    hl.dispatch(hl.dsp.submap("reset"))
  end)

  hl.bind("escape", hl.dsp.submap("reset"))
  hl.bind("SUPER+M", hl.dsp.submap("reset"))
end)

-- Vscodium
hl.bind("SUPER+V", hl.dsp.exec_cmd("codium"))
hl.bind("SUPER+SHIFT+V", hl.dsp.exec_cmd("codium ~/nixos-config"))

-- Screenshot
hl.bind("SUPER+S", hl.dsp.exec_cmd("grimblast --notify copysave area ~/Pictures/screenshots/$(date +'%Y-%m-%d-At-%Hh%Mm%Ss').png"))
hl.bind("SUPER+CTRL+S", hl.dsp.exec_cmd("bash -c 'tmp=$(mktemp /tmp/ocr-XXXX.png) && grimblast save area \"$tmp\" && tesseract $tmp stdout 2>/dev/null | wl-copy && notify-send \"OCR complete\" \"Copied to clipboard\"'"))
hl.bind("SUPER+SHIFT+S", hl.dsp.exec_cmd("my-screenrecording"))

-- Focus
hl.bind("SUPER+left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER+right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER+up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER+down", hl.dsp.focus({ direction = "down" }))

hl.bind("SUPER+ALT+E", hl.dsp.window.move({ workspace = "emptynm" }))

-- Window controls
hl.bind("SUPER+Q", hl.dsp.window.close())
hl.bind("SUPER+F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER+Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER+J", hl.dsp.layout("togglesplit"))
hl.bind("SUPER+ALT+G", smw.grab_rogue_windows())

-- Cycle
-- Two actions on one key go in ONE bind (a second hl.bind on the same key
-- doesn't reliably stack - see the "Multiple binds to one key" wiki section).
hl.bind("ALT+Tab", function()
  hl.dispatch(hl.dsp.window.cycle_next({ next = true }))
  hl.dispatch(hl.dsp.window.bring_to_top())
end)
hl.bind("ALT+SHIFT+Tab", function()
  hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
  hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- Move the active window to the previous/next monitor and follow it. The old
-- split-changemonitor dispatcher is gone with the C++ plugin; smw's own docs
-- use the native monitor move for this.
hl.bind("SUPER+SHIFT+comma", hl.dsp.window.move({ monitor = "-1", follow = true }))
hl.bind("SUPER+SHIFT+period", hl.dsp.window.move({ monitor = "+1", follow = true }))

-- Move windows
hl.bind("SUPER+SHIFT+left", hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER+SHIFT+right", hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER+SHIFT+up", hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER+SHIFT+down", hl.dsp.window.move({ direction = "down" }))

-- Resize windows. resize({x, y}) is ABSOLUTE unless relative = true, so without
-- it -80 is a negative target size -> "invalid size". (The old resizeactive
-- dispatcher was always relative.)
hl.bind("SUPER+CTRL+left", hl.dsp.window.resize({ x = -80, y = 0, relative = true }))
hl.bind("SUPER+CTRL+right", hl.dsp.window.resize({ x = 80, y = 0, relative = true }))
hl.bind("SUPER+CTRL+up", hl.dsp.window.resize({ x = 0, y = -80, relative = true }))
hl.bind("SUPER+CTRL+down", hl.dsp.window.resize({ x = 0, y = 80, relative = true }))

-- Move floating (relative nudge, same as the old "moveactive" dispatcher)
hl.bind("SUPER+ALT+left", hl.dsp.window.move({ x = -80, y = 0, relative = true }))
hl.bind("SUPER+ALT+right", hl.dsp.window.move({ x = 80, y = 0, relative = true }))
hl.bind("SUPER+ALT+up", hl.dsp.window.move({ x = 0, y = -80, relative = true }))
hl.bind("SUPER+ALT+down", hl.dsp.window.move({ x = 0, y = 80, relative = true }))

-- Workspace switching (split-monitor-workspaces Lua API)
for i = 1, 10 do
  local n = tostring(i)
  local key = (i == 10) and "0" or n
  hl.bind("SUPER+" .. key, smw.workspace(n))
  hl.bind("SUPER+SHIFT+" .. key, smw.move_to_workspace_silent(n))
end

-- Workspace scroll
hl.bind("SUPER+mouse_up", smw.cycle_workspaces("next"))
hl.bind("SUPER+mouse_down", smw.cycle_workspaces("prev"))
hl.bind("SUPER+Tab", smw.cycle_workspaces("next"))
hl.bind("SUPER+SHIFT+Tab", smw.cycle_workspaces("prev"))

-- Locked binds (work on lockscreen)
-- hl.bind takes ONE combined "mods+key" string, not separate (mods, key)
-- args like the old bindl/bindm did - empty mods means just the bare key.
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true })
hl.bind("SUPER+XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 100%+"), { locked = true })
hl.bind("SUPER+XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 100%-"), { locked = true })

-- Desktop brightness (uses DDCutil)
hl.bind("code:233", hl.dsp.exec_cmd("ddcutil --display $(hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | grep -q DP && echo 2 || echo 1) setvcp 10 + 10"), { locked = true })
hl.bind("code:232", hl.dsp.exec_cmd("ddcutil --display $(hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | grep -q DP && echo 2 || echo 1) setvcp 10 - 10"), { locked = true })
hl.bind("SUPER+code:233", hl.dsp.exec_cmd("ddcutil --display $(hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | grep -q DP && echo 2 || echo 1) setvcp 10 100"), { locked = true })
hl.bind("SUPER+code:232", hl.dsp.exec_cmd("ddcutil --display $(hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | grep -q DP && echo 2 || echo 1) setvcp 10 0"), { locked = true })

-- Media and volume controls (these were dropped in the Lua migration)
local player = "playerctl -p $(cat ${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player)"
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 2"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 2"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(player .. " play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(player .. " next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(player .. " previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd(player .. " stop"), { locked = true })

-- Misc locked
hl.bind("SUPER+ALT+R", hl.dsp.exec_cmd("my-refresh"), { locked = true })

-- Shutdown options
hl.bind("SUPER+Escape", hl.dsp.exec_cmd("systemctl --user start hyprlock.service"), { locked = true })
hl.bind("SUPER+SHIFT+Escape", hl.dsp.exec_cmd("my-sleep"), { locked = true })
hl.bind("SUPER+SHIFT+CTRL+Escape", hl.dsp.exec_cmd("hyprshutdown -t 'Shutting down...' --post-cmd 'my-shutdown'"), { locked = true })
hl.bind("SUPER+SHIFT+CTRL+ALT+Escape", hl.dsp.exec_cmd("hyprshutdown -t 'Restarting...' --post-cmd 'reboot'"), { locked = true })
hl.bind("switch:Lid Switch", hl.dsp.exec_cmd("my-sleep"), { locked = true })

-- Mouse bindings (window drag/resize via mouse button + modifier)
hl.bind("SUPER+mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER+mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Touchpad: 3-finger horizontal swipe switches workspace (was `gesture = 3, horizontal, workspace`)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
