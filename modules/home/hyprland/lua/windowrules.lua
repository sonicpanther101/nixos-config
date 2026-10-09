-- Window rules migrated from modules/home/hyprland/windowrules.nix
-- Symlinked to ~/.config/hypr/windowrules.lua at activation
-- Changes trigger hyprctl reload only (no Nix rebuild needed)
--
-- NOTE: hl.window_rule's `size`/`move` effects take a "WxH" / "X Y" STRING
-- (e.g. "950x600", "0 0"), not a Lua table - a table silently fails to error
-- at parse time but wouldn't do what's intended, so both helpers below build
-- the string form. See docs: https://alejandrominaya.github.io/hyprland-lua-docs/

-- Helper: create float + center rules for a match.
-- `match` is a full match table, e.g. { class = "foo" } or
-- { class = "foo", title = "bar" }. Multiple keys are ANDed together.
local function mkFloatRule(match, size)
  hl.window_rule({
    match = match,
    float = true,
    center = true,
  })
  if size then
    hl.window_rule({
      match = match,
      -- Space-separated "WIDTH HEIGHT", not "WIDTHxHEIGHT" - the live
      -- parser error ("vec2 requires two expressions separated by
      -- whitespace") is the source of truth here, not the third-party docs.
      size = size[1] .. " " .. size[2],
    })
  end
end

-- Helper: create multiple float rules at once
local function mkFloatRules(rules)
  for _, r in ipairs(rules) do
    mkFloatRule(r.match, r.size)
  end
end

-- Float by class
mkFloatRules({
  { match = { class = "Matplotlib" }, size = { 950, 600 } },
  { match = { class = "float_nemo" }, size = { 950, 600 } },
  { match = { class = "imv" }, size = { 1200, 725 } },
  { match = { class = "mpv" }, size = { 1200, 725 } },
})

-- Float by title (or class + title)
mkFloatRules({
  { match = { title = "float_kitty" }, size = { 950, 600 } },
  { match = { title = "Open Folder" }, size = { 950, 600 } },
  { match = { title = "Open File" }, size = { 950, 600 } },
  { match = { title = "Open file" }, size = { 950, 600 } },
  { match = { title = "Open Files" }, size = { 950, 600 } },
  { match = { title = "Save File" }, size = { 950, 600 } },
  { match = { class = "thunderbird", title = ".*Reminder.*" }, size = { 600, 200 } },
  { match = { title = "Extract" }, size = { 850, 200 } },
  { match = { title = "Active connection found" } },
  { match = { title = "Edit Item" } },
  { match = { title = "OpenRGB" } },
  { match = { title = ".*Physics Simulation.*" } },
  { match = { title = "Pipewire Volume Control" } },
  { match = { title = ".*Properties.*" } },
})

-- Helper: create a rule with multiple properties
local function mkRule(opts)
  hl.window_rule(opts)
end

-- Opacity rules
mkRule({ match = { class = "codium" }, opacity = "0.9" })
mkRule({ match = { class = "foobar2000.exe" }, opacity = "0.9" })
mkRule({ match = { class = "vivaldi-stable" }, opacity = "0.9" })
mkRule({ match = { title = ".*Last.fm.*" }, opacity = "1" })
mkRule({ match = { title = ".*Movie.*" }, opacity = "1" })
mkRule({ match = { class = "nemo" }, opacity = "0.75" })

-- SableUI rules
mkRule({ match = { title = ".*SableUI.*" }, float = true, pin = true, border_size = 0, no_anim = true, no_shadow = true, no_blur = true, no_initial_focus = true, move = "0 0" })

-- Idle inhibit rules
mkRule({ match = { class = "mpv" }, idle_inhibit = "focus" })
mkRule({ match = { class = "vlc" }, idle_inhibit = "focus" })
mkRule({ match = { title = ".*Syncthing.*" }, idle_inhibit = "focus" })
mkRule({ match = { title = ".*LEARN.*" }, idle_inhibit = "focus" })
mkRule({ match = { title = ".*Tutorial.*" }, idle_inhibit = "focus" })
mkRule({ match = { title = ".*Lab Report.*" }, idle_inhibit = "focus" })
mkRule({ match = { title = ".*homework.*" }, idle_inhibit = "focus" })
mkRule({ match = { title = "cava" }, idle_inhibit = "focus" })

mkRule({ match = { class = "foobar2000.exe" }, workspace = "13 silent" })

-- Layer rules
-- `namespace` is a match criterion (goes inside match={}), and there is no
-- `level` field - the old hyprlang "level" concept is `above_lock` (int 0-2)
-- here. These three were meant to render above the lock screen, so above_lock
-- = 2 (the max) replaces the old `level = 2, above_lock = true` pairing.
hl.layer_rule({ match = { namespace = "wvkbd" }, above_lock = 2 })
hl.layer_rule({ match = { namespace = "waybar" }, above_lock = 2 })
hl.layer_rule({ match = { namespace = "sunshine" }, above_lock = 2 })
