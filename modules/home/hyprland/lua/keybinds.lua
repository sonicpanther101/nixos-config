-- Keybinds migrated from modules/home/hyprland/keybinds.nix
-- Symlinked to ~/.config/hypr/keybinds.lua at activation
-- Changes trigger hyprctl reload only (no Nix rebuild needed)

-- Terminal
hl.bind("SUPER, Return", hl.dsp.exec_cmd("kitty"))
hl.bind("ALT, Return", hl.dsp.exec_cmd("kitty --title float_kitty"))
hl.bind("SUPER SHIFT, Return", hl.dsp.exec_cmd('kitty --start-as=fullscreen -o "font_size=16"'))

-- Browser
hl.bind("SUPER, B", hl.dsp.exec_cmd('vivaldi --profile-directory="Default" --allowlisted-extension-id=clngdbkpkpeebahjckkjfobafhncgmne'))
hl.bind("SUPER SHIFT, B", hl.dsp.exec_cmd('vivaldi --profile-directory="Profile 1"'))

-- File browser
hl.bind("SUPER, E", hl.dsp.exec_cmd("nemo"))
hl.bind("ALT, E", hl.dsp.exec_cmd("nemo --name=float_nemo"))

-- Note taking
hl.bind("SUPER, N", hl.dsp.exec_cmd("xournalpp"))
hl.bind("SUPER ALT, N", hl.dsp.exec_cmd("sleep 2 && wlrctl pointer move 1 1 || true"))

-- Misc
hl.bind("SUPER, R", hl.dsp.exec_cmd("walker"))
hl.bind("ALT, V", hl.dsp.exec_cmd("walker -m clipboard"))
hl.bind("SUPER, period", hl.dsp.exec_cmd("walker -m symbols"))
hl.bind("SUPER, W", hl.dsp.exec_cmd("walker -m menus:wallpapers"))
hl.bind("SUPER, F1", hl.dsp.exec_cmd("walker -m menus:keybinds"))
hl.bind("SUPER, F2", hl.dsp.exec_cmd("walker -m menus:aliases"))
hl.bind("SUPER ALT, W", hl.dsp.exec_cmd("systemctl --user restart waybar.service"))
hl.bind("SUPER ALT, K", hl.dsp.exec_cmd("my-toggle-keyboard"))
hl.bind("SUPER ALT, P", hl.dsp.exec_cmd("beefweb_mpris"))
hl.bind("SUPER, C", hl.dsp.exec_cmd("hyprpicker -a"))

-- Submap entry
hl.bind("SUPER, M", function()
  hl.dsp.submap("monitor")
end)

-- Vscodium
hl.bind("SUPER, V", hl.dsp.exec_cmd("codium"))
hl.bind("SUPER SHIFT, V", hl.dsp.exec_cmd("codium ~/nixos-config"))

-- Screenshot
hl.bind("SUPER, S", hl.dsp.exec_cmd("grimblast --notify copysave area ~/Pictures/screenshots/$(date +'%Y-%m-%d-At-%Hh%Mm%Ss').png"))
hl.bind("SUPER CTRL, S", hl.dsp.exec_cmd("bash -c 'tmp=$(mktemp /tmp/ocr-XXXX.png) && grimblast save area \"$tmp\" && tesseract $tmp stdout 2>/dev/null | wl-copy && notify-send \"OCR complete\" \"Copied to clipboard\"'"))
hl.bind("SUPER SHIFT, S", hl.dsp.exec_cmd("my-screenrecording"))

-- Focus
hl.bind("SUPER, left", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER, right", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER, up", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER, down", hl.dsp.focus({ direction = "d" }))

hl.bind("SUPER ALT, E", hl.dsp.movetoworkspace("emptynm"))

-- Window controls
hl.bind("SUPER, Q", hl.dsp.killactive())
hl.bind("SUPER, F", hl.dsp.fullscreen(0))
hl.bind("SUPER, Space", hl.dsp.togglefloating())
hl.bind("SUPER, J", hl.dsp.layoutmsg("togglesplit"))
hl.bind("SUPER ALT, G", hl.dsp.layoutmsg("split-grabroguewindows"))

-- Cycle
hl.bind("ALT, Tab", hl.dsp.cyclenext())
hl.bind("ALT, Tab", hl.dsp.bringactivetotop())
hl.bind("ALT SHIFT, Tab", hl.dsp.cyclenext({ forward = false }))
hl.bind("ALT SHIFT, Tab", hl.dsp.bringactivetotop())

-- Monitor movement
hl.bind("SUPER SHIFT, comma", hl.dsp.exec_cmd("split-changemonitor prev"))
hl.bind("SUPER SHIFT, period", hl.dsp.exec_cmd("split-changemonitor next"))

-- Move windows
hl.bind("SUPER SHIFT, left", hl.dsp.movewindow({ direction = "l" }))
hl.bind("SUPER SHIFT, right", hl.dsp.movewindow({ direction = "r" }))
hl.bind("SUPER SHIFT, up", hl.dsp.movewindow({ direction = "u" }))
hl.bind("SUPER SHIFT, down", hl.dsp.movewindow({ direction = "d" }))

-- Resize windows
hl.bind("SUPER CTRL, left", hl.dsp.resizeactive({ x = -80, y = 0 }))
hl.bind("SUPER CTRL, right", hl.dsp.resizeactive({ x = 80, y = 0 }))
hl.bind("SUPER CTRL, up", hl.dsp.resizeactive({ x = 0, y = -80 }))
hl.bind("SUPER CTRL, down", hl.dsp.resizeactive({ x = 0, y = 80 }))

-- Move floating
hl.bind("SUPER ALT, left", hl.dsp.moveactive({ x = -80, y = 0 }))
hl.bind("SUPER ALT, right", hl.dsp.moveactive({ x = 80, y = 0 }))
hl.bind("SUPER ALT, up", hl.dsp.moveactive({ x = 0, y = -80 }))
hl.bind("SUPER ALT, down", hl.dsp.moveactive({ x = 0, y = 80 }))

-- Workspace switching (split-monitor-workspaces)
for i = 1, 10 do
  hl.bind("SUPER, " .. tostring(i), hl.dsp.exec_cmd("split-workspace " .. tostring(i)))
  hl.bind("SUPER SHIFT, " .. tostring(i), hl.dsp.exec_cmd("split-movetoworkspacesilent " .. tostring(i)))
end

-- Workspace scroll
hl.bind("SUPER, mouse_up", hl.dsp.exec_cmd("split-cycleworkspaces +1"))
hl.bind("SUPER, mouse_down", hl.dsp.exec_cmd("split-cycleworkspaces -1"))
hl.bind("SUPER, Tab", hl.dsp.exec_cmd("split-cycleworkspaces +1"))
hl.bind("SUPER SHIFT, Tab", hl.dsp.exec_cmd("split-cycleworkspaces -1"))

-- Locked binds (work on lockscreen)
hl.bindl("", "XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"))
hl.bindl("", "XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))
hl.bindl("SUPER", "XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 100%+"))
hl.bindl("SUPER", "XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 100%-"))

-- Desktop brightness (uses DDCutil)
hl.bindl("", "code:233", hl.dsp.exec_cmd("ddcutil --display $(hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | grep -q DP && echo 2 || echo 1) setvcp 10 + 10"))
hl.bindl("", "code:232", hl.dsp.exec_cmd("ddcutil --display $(hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | grep -q DP && echo 2 || echo 1) setvcp 10 - 10"))
hl.bindl("SUPER", "code:233", hl.dsp.exec_cmd("ddcutil --display $(hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | grep -q DP && echo 2 || echo 1) setvcp 10 100"))
hl.bindl("SUPER", "code:232", hl.dsp.exec_cmd("ddcutil --display $(hyprctl monitors -j | jq '.[] | select(.focused == true) | .name' | grep -q DP && echo 2 || echo 1) setvcp 10 0"))

-- Misc locked
hl.bindl("SUPER ALT, R", hl.dsp.exec_cmd("my-refresh"))

-- Shutdown options
hl.bindl("SUPER, Escape", hl.dsp.exec_cmd("systemctl --user start hyprlock.service"))
hl.bindl("SUPER SHIFT, Escape", hl.dsp.exec_cmd("my-sleep"))
hl.bindl("SUPER SHIFT CTRL, Escape", hl.dsp.exec_cmd("hyprshutdown -t 'Shutting down...' --post-cmd 'my-shutdown'"))
hl.bindl("SUPER SHIFT CTRL ALT, Escape", hl.dsp.exec_cmd("hyprshutdown -t 'Restarting...' --post-cmd 'reboot'"))
hl.bindl("", "switch:Lid Switch", hl.dsp.exec_cmd("my-sleep"))

-- Mouse bindings
hl.bindm("SUPER", "mouse:272", hl.dsp.movewindow())
hl.bindm("SUPER", "mouse:273", hl.dsp.resizewindow())
