-- Hyprgrass gestures migrated from hyprland.nix extraConfig (touch_gestures block)
-- Symlinked to ~/.config/hypr/hyprgrass-gestures.lua at activation
-- Changes trigger hyprctl reload only (no Nix rebuild needed)

-- Plugin config
hl.config({
  plugin = {
    hyprgrass = {
      -- Tablet screens generally need more sensitivity than the 1.0 default.
      sensitivity = 3.0,

      -- Must be >= 3. Deliberately set high (out of the way of the 3/4-finger
      -- discrete gestures below) since workspace switching is handled by the
      -- swipe:4:l/r binds -> split-cycleworkspaces instead of this drag-to-follow
      -- continuous swipe.
      workspace_swipe_fingers = 5,

      -- Continuous edge-drag workspace switching, separate from workspace_swipe_fingers.
      -- Disabled (set to a non l/r/u/d value) because every edge below is already
      -- used for a discrete quick-launch gesture and would otherwise collide with it.
      workspace_swipe_edge = "none",

      -- In milliseconds
      long_press_delay = 400,

      -- Resize windows by long-pressing on window borders and gaps.
      resize_on_border_long_press = true,

      -- In pixels, the distance from the edge that is considered an edge
      edge_margin = 10,
    },
  },
})

-- Built-in gesture config
hl.config({
  gestures = {
    workspace_swipe_cancel_ratio = 0.15,
  },
})

-- --- Edge swipes: quick-launch ---
-- swipe left from right edge -> xournalpp
hl.plugin.hyprgrass.bind({
  pattern = { kind = "edge", origin = "right", direction = "left" },
  action = hl.dsp.exec_cmd("xournalpp"),
})

-- swipe up from right edge -> toggle keyboard
hl.plugin.hyprgrass.bind({
  pattern = { kind = "edge", origin = "right", direction = "up" },
  action = hl.dsp.exec_cmd("my-toggle-keyboard"),
})

-- swipe down from right edge -> move pointer
hl.plugin.hyprgrass.bind({
  pattern = { kind = "edge", origin = "right", direction = "down" },
  action = hl.dsp.exec_cmd("sleep 2 && wlrctl pointer move 1 1 || true"),
})

-- swipe up from bottom edge -> browser
hl.plugin.hyprgrass.bind({
  pattern = { kind = "edge", origin = "down", direction = "up" },
  action = hl.dsp.exec_cmd('vivaldi --profile-directory="Default" --allowlisted-extension-id=clngdbkpkpeebahjckkjfobafhncgmne'),
})

-- swipe right from bottom edge -> work browser
hl.plugin.hyprgrass.bind({
  pattern = { kind = "edge", origin = "down", direction = "right" },
  action = hl.dsp.exec_cmd('vivaldi --profile-directory="Profile 1"'),
})

-- swipe down from left edge -> volume down
hl.plugin.hyprgrass.bind({
  pattern = { kind = "edge", origin = "left", direction = "down" },
  action = hl.dsp.exec_cmd("pamixer -d 4"),
})

-- swipe up from left edge -> volume up
hl.plugin.hyprgrass.bind({
  pattern = { kind = "edge", origin = "left", direction = "up" },
  action = hl.dsp.exec_cmd("pamixer -i 4"),
})

-- swipe from top edge -> power options
hl.plugin.hyprgrass.bind({
  pattern = { kind = "edge", origin = "up", direction = "left" },
  action = hl.dsp.exec_cmd("systemctl --user start hyprlock.service"),
})
hl.plugin.hyprgrass.bind({
  pattern = { kind = "edge", origin = "up", direction = "down" },
  action = hl.dsp.exec_cmd("my-sleep"),
})
hl.plugin.hyprgrass.bind({
  pattern = { kind = "edge", origin = "up", direction = "right" },
  action = hl.dsp.exec_cmd("hyprshutdown -t 'Shutting down...' --post-cmd 'my-shutdown'"),
})

-- --- 4-finger swipes: workspaces + window state ---
hl.plugin.hyprgrass.gesture({
  pattern = { kind = "swipe", fingers = 4, direction = "left" },
  action = "split-cycleworkspaces +1",
})
hl.plugin.hyprgrass.gesture({
  pattern = { kind = "swipe", fingers = 4, direction = "right" },
  action = "split-cycleworkspaces -1",
})
hl.plugin.hyprgrass.gesture({
  pattern = { kind = "swipe", fingers = 4, direction = "down" },
  action = "fullscreen",
})
hl.plugin.hyprgrass.gesture({
  pattern = { kind = "swipe", fingers = 4, direction = "up" },
  action = "float",
})

-- --- 3-finger swipes: focus + layout ---
hl.plugin.hyprgrass.gesture({
  pattern = { kind = "swipe", fingers = 3, direction = "left" },
  action = "movefocus l",
})
hl.plugin.hyprgrass.gesture({
  pattern = { kind = "swipe", fingers = 3, direction = "right" },
  action = "movefocus r",
})
hl.plugin.hyprgrass.gesture({
  pattern = { kind = "swipe", fingers = 3, direction = "down" },
  action = "layoutmsg togglesplit",
})
hl.plugin.hyprgrass.gesture({
  pattern = { kind = "swipe", fingers = 3, direction = "up" },
  action = "layoutmsg swapsplit",
})

-- tap with 3 fingers -> terminal (conditional on not Xournal++)
hl.plugin.hyprgrass.bind({
  pattern = { kind = "tap", fingers = 3 },
  action = function()
    local win = hl.get_active_window()
    if win and not string.match(win.title, "Xournal++") then
      hl.dsp.exec_cmd("kitty")
    end
  end,
})

-- pinch in with 3 fingers -> file manager
hl.plugin.hyprgrass.bind({
  pattern = { kind = "pinch", fingers = 3, direction = "pinchin" },
  action = hl.dsp.exec_cmd("nemo"),
})

-- 5-finger tap/pinch -> close window
hl.plugin.hyprgrass.bind({
  pattern = { kind = "tap", fingers = 5 },
  action = hl.dsp.killactive(),
})
hl.plugin.hyprgrass.bind({
  pattern = { kind = "pinch", fingers = 5, direction = "pinchin" },
  action = hl.dsp.killactive(),
})

-- longpress can trigger mouse binds
hl.plugin.hyprgrass.bind({
  pattern = { kind = "longpress", fingers = 2 },
  action = hl.dsp.window.drag(),
  mouse = true,
})
hl.plugin.hyprgrass.bind({
  pattern = { kind = "longpress", fingers = 3 },
  action = hl.dsp.window.resize(),
  mouse = true,
})
