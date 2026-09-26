-- Window rules migrated from modules/home/hyprland/windowrules.nix
-- Symlinked to ~/.config/hypr/windowrules.lua at activation
-- Changes trigger hyprctl reload only (no Nix rebuild needed)

-- Helper: create float + center rules for a match
local function mkFloatRule(match, type, size)
  hl.window_rule({
    match = { [type] = match },
    float = true,
    center = true,
  })
  if size then
    hl.window_rule({
      match = { [type] = match },
      size = { size[1], size[2] },
    })
  end
end

-- Helper: create multiple float rules at once
local function mkFloatRules(rules)
  for _, r in ipairs(rules) do
    mkFloatRule(r.match, r.type, r.size)
  end
end

-- Float by class
mkFloatRules({
  { match = "Matplotlib", type = "class", size = { 950, 600 } },
  { match = "float_nemo", type = "class", size = { 950, 600 } },
  { match = "imv", type = "class", size = { 1200, 725 } },
  { match = "mpv", type = "class", size = { 1200, 725 } },
})

-- Float by title
mkFloatRules({
  { match = "float_kitty", type = "title", size = { 950, 600 } },
  { match = "Open Folder", type = "title", size = { 950, 600 } },
  { match = "Open File", type = "title", size = { 950, 600 } },
  { match = "Open file", type = "title", size = { 950, 600 } },
  { match = "Open Files", type = "title", size = { 950, 600 } },
  { match = "Save File", type = "title", size = { 950, 600 } },
  { match = ".* Reminders", type = "title", size = { 600, 200 } },
  { match = "Extract", type = "title", size = { 850, 200 } },
  { match = "Active connection found", type = "title" },
  { match = "Edit Item", type = "title" },
  { match = "Calendar Reminders", type = "title" },
  { match = "OpenRGB", type = "title" },
  { match = ".*Physics Simulation.*", type = "title" },
  { match = "Pipewire Volume Control", type = "title" },
  { match = ".*Properties.*", type = "title" },
})

-- Helper: create a rule with multiple properties
local function mkRule(opts)
  hl.window_rule(opts)
end

-- Opacity rules
mkRule({ match = { class = "codium" }, opacity = 0.9 })
mkRule({ match = { class = "foobar2000.exe" }, opacity = 0.9 })
mkRule({ match = { class = "vivaldi-stable" }, opacity = 0.9 })
mkRule({ match = { title = ".*Last.fm" }, opacity = 1 })
mkRule({ match = { title = ".*Movie" }, opacity = 1 })
mkRule({ match = { class = "nemo" }, opacity = 0.75 })

-- SableUI rules
mkRule({ match = { title = ".*SableUI.*" }, pin = true, border_size = 0, no_anim = true, no_shadow = true, no_blur = true, no_initial_focus = true, move = { 0, 0 } })

-- Idle inhibit rules
mkRule({ match = { class = "mpv" }, idle_inhibit = "focus" })
mkRule({ match = { class = "vlc" }, idle_inhibit = "focus" })
mkRule({ match = { title = ".*Syncthing.*" }, idle_inhibit = "focus" })
mkRule({ match = { title = ".*LEARN.*" }, idle_inhibit = "focus" })
mkRule({ match = { title = ".*Tutorial.*" }, idle_inhibit = "focus" })
mkRule({ match = { title = ".*Lab Report.*" }, idle_inhibit = "focus" })
mkRule({ match = { title = ".*homework.*" }, idle_inhibit = "focus" })
mkRule({ match = { title = "cava" }, idle_inhibit = "focus" })

-- Layer rules
hl.layer_rule({ namespace = "wvkbd", level = 2, above_lock = true })
hl.layer_rule({ namespace = "waybar", level = 2, above_lock = true })
hl.layer_rule({ namespace = "sunshine", level = 2, above_lock = true })
