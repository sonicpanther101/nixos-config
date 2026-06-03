Name = "keybinds"
NamePretty = "Hyprland Keybinds"
Icon = "input-keyboard"
Cache = false
SearchName = true

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

local CAT_ORDER = {
    "Launch", "Window", "Focus", "Resize", "Float",
    "Workspace", "Monitor", "System", "Other",
}

local CAT_MAP = {
    exec                            = "Launch",
    killactive                      = "Window",
    fullscreen                      = "Window",
    togglefloating                  = "Window",
    movetoworkspace                 = "Window",
    cyclenext                       = "Window",
    layoutmsg                       = "Window",
    movefocus                       = "Focus",
    movewindow                      = "Focus",
    resizeactive                    = "Resize",
    moveactive                      = "Float",
    workspace                       = "Workspace",
    ["split-workspace"]             = "Workspace",
    ["split-movetoworkspacesilent"] = "Workspace",
    ["split-cycleworkspaces"]       = "Workspace",
    ["split-changemonitorsilent"]   = "Monitor",
    ["split-grabroguewindows"]      = "Monitor",
    dpms                            = "System",
}

local DISPATCHERS_4 = {
    movefocus  = "Move focus",
    movewindow = "Move window",
    resizeactive = "Resize window",
    moveactive   = "Move floating",
}

local DISPATCHERS_2 = { ["split-changemonitorsilent"] = true }

local function cat_index(cat)
    for i, v in ipairs(CAT_ORDER) do
        if v == cat then return i end
    end
    return 999
end

local function trim(s)
    return s:gsub("^%s+", ""):gsub("%s+$", "")
end

----------------------------------------------------------------------
-- Modifier mask
----------------------------------------------------------------------

local function has_flag(mask, flag)
    return math.floor(mask / flag) % 2 == 1
end

local function mod_str(mask)
    local parts = {}
    if has_flag(mask, 64) then table.insert(parts, "Super") end
    if has_flag(mask, 1)  then table.insert(parts, "Shift") end
    if has_flag(mask, 4)  then table.insert(parts, "Ctrl")  end
    if has_flag(mask, 8)  then table.insert(parts, "Alt")   end
    return table.concat(parts, " + ")
end

----------------------------------------------------------------------
-- Key formatting
----------------------------------------------------------------------

local KEY_MAP = {
    Return = "Enter", comma = ",", period = ".", semicolon = ";",
    space = "Space", escape = "Esc",
    left = "←", right = "→", up = "↑", down = "↓",
    XF86AudioRaiseVolume  = "Vol↑",   XF86AudioLowerVolume = "Vol↓",
    XF86AudioMute         = "Mute",   XF86AudioPlay        = "Play/Pause",
    XF86AudioNext         = "Next",   XF86AudioPrev        = "Prev",
    XF86AudioStop         = "Stop",
    XF86MonBrightnessUp   = "Bright↑",XF86MonBrightnessDown = "Bright↓",
    mouse_up    = "Scroll↑", mouse_down  = "Scroll↓",
    ["mouse:272"] = "LClick", ["mouse:273"] = "RClick",
}

local KEYCODE_MAP = { [233] = "Bright↑", [232] = "Bright↓" }

local function fmt_key(key, keycode)
    if (key == nil or key == "") and keycode and keycode ~= 0 then
        return KEYCODE_MAP[keycode] or ("key:" .. tostring(keycode))
    end
    return KEY_MAP[key] or key
end

----------------------------------------------------------------------
-- Direction helpers
----------------------------------------------------------------------

local function canonical_dir(arg)
    local a = trim(string.lower(arg or ""))
    if a == "l" or a == "left"         then return "←" end
    if a == "r" or a == "right"        then return "→" end
    if a == "u" or a == "up"           then return "↑" end
    if a == "d" or a == "down"         then return "↓" end
    if a == "prev" or a == "-1"        then return "←" end
    if a == "next" or a == "+1"        then return "→" end
    local x, y = a:match("^(-?%d+)%s+(-?%d+)$")
    if x then
        x, y = tonumber(x), tonumber(y)
        if x < 0 then return "←" end
        if x > 0 then return "→" end
        if y < 0 then return "↑" end
        if y > 0 then return "↓" end
    end
    return nil
end

----------------------------------------------------------------------
-- Action descriptions
----------------------------------------------------------------------

local function fmt_action(dispatcher, arg)
    arg = trim(arg or "")
    if dispatcher == "exec" then
        return arg
    elseif dispatcher == "killactive" then
        return "Close window"
    elseif dispatcher == "fullscreen" then
        return "Fullscreen"
    elseif dispatcher == "togglefloating" then
        return "Toggle float"
    elseif dispatcher == "movetoworkspace" then
        return "Move window → workspace " .. arg
    elseif dispatcher == "split-workspace" then
        return "Switch to workspace " .. arg
    elseif dispatcher == "split-movetoworkspacesilent" then
        return "Move window → workspace " .. arg .. " (silent)"
    elseif dispatcher == "split-grabroguewindows" then
        return "Grab windows orphaned by disconnected monitor"
    elseif dispatcher == "split-cycleworkspaces" then
        local sym = (arg == "+1" or arg == "next") and "→" or "←"
        return "Cycle workspaces " .. sym
    elseif dispatcher == "movefocus" then
        local d = canonical_dir(arg)
        return d and ("Move focus " .. d) or ("Move focus " .. arg)
    elseif dispatcher == "movewindow" then
        local d = canonical_dir(arg)
        return d and ("Move window " .. d) or ("Move window " .. arg)
    elseif dispatcher == "split-changemonitorsilent" then
        local d = canonical_dir(arg)
        return d and ("Move window " .. d .. " monitor (silent)") or ("Move window to " .. arg .. " monitor (silent)")
    elseif dispatcher == "resizeactive" then
        local dx, dy = arg:match("^(-?%d+)%s+(-?%d+)$")
        if dx then
            dx, dy = tonumber(dx), tonumber(dy)
            local parts = {}
            if dx ~= 0 then table.insert(parts, (dx > 0 and "→" or "←") .. " " .. math.abs(dx) .. "px") end
            if dy ~= 0 then table.insert(parts, (dy > 0 and "↓" or "↑") .. " " .. math.abs(dy) .. "px") end
            return "Resize  " .. table.concat(parts, "  ")
        end
        return "Resize " .. arg
    elseif dispatcher == "moveactive" then
        local dx, dy = arg:match("^(-?%d+)%s+(-?%d+)$")
        if dx then
            dx, dy = tonumber(dx), tonumber(dy)
            local arrows = (dx > 0 and "→" or dx < 0 and "←" or "") ..
                           (dy > 0 and "↓" or dy < 0 and "↑" or "")
            return "Move floating " .. arrows
        end
        return "Move floating " .. arg
    elseif dispatcher == "cyclenext" then
        return "Cycle window " .. (arg:find("prev") and "← prev" or "→ next")
    elseif dispatcher == "bringactivetotop" then
        return nil
    elseif dispatcher == "layoutmsg" then
        return "Layout: " .. arg
    elseif dispatcher == "dpms" then
        return "Display power: " .. arg
    elseif dispatcher == "workspace" then
        return "Switch to workspace " .. arg
    else
        return trim(dispatcher .. " " .. arg)
    end
end

----------------------------------------------------------------------
-- Notification / dispatch actions
----------------------------------------------------------------------

function GroupedEntry(value, args)
    os.execute(
        "notify-send 'Grouped keybind entry' " ..
        "'This row represents multiple related keybinds and cannot be executed directly.'"
    )
end

function RunBind(value, args)
    local dispatcher, arg = value:match("^(.-)\31(.*)$")
    if not dispatcher or dispatcher == "" then return end
    if dispatcher == "exec" then
        os.execute(string.format("hyprctl dispatch exec -- %q >/dev/null 2>&1 &", arg))
    else
        os.execute(string.format("hyprctl dispatch %s %q >/dev/null 2>&1 &", dispatcher, arg))
    end
end

----------------------------------------------------------------------
-- Load binds
----------------------------------------------------------------------

local function load_binds()
    local binds = {}
    local cmd = [[hyprctl binds -j | jq -r '.[] | [
        (.dispatcher // ""),
        (.arg // ""),
        (.key // ""),
        (.keycode // 0),
        (.modmask // 0)
    ] | @tsv']]
    local h = io.popen(cmd)
    if not h then return binds end
    for line in h:lines() do
        local dispatcher, arg, key, keycode, modmask =
            line:match("([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)")
        table.insert(binds, {
            dispatcher = dispatcher,
            arg        = arg,
            key        = key,
            keycode    = tonumber(keycode) or 0,
            modmask    = tonumber(modmask) or 0,
        })
    end
    h:close()
    return binds
end

----------------------------------------------------------------------
-- Collapse workspace groups (sequential numeric, e.g. 1–10)
----------------------------------------------------------------------

local function collapse_workspace_groups(raw)
    local skip  = {}   -- set of table references to suppress
    local extra = {}   -- new collapsed entries to add

    for _, disp in ipairs({ "split-workspace", "split-movetoworkspacesilent" }) do
        -- group by modmask
        local by_mask = {}
        for _, b in ipairs(raw) do
            if b.dispatcher == disp then
                local m = b.modmask
                by_mask[m] = by_mask[m] or {}
                table.insert(by_mask[m], b)
            end
        end

        for mask, members in pairs(by_mask) do
            -- keep only numeric args
            local numeric = {}
            for _, m in ipairs(members) do
                local n = tonumber(m.arg)
                if n then table.insert(numeric, { n = n, b = m }) end
            end
            if #numeric < 3 then goto continue end

            table.sort(numeric, function(a, b) return a.n < b.n end)

            -- check contiguous
            local lo, hi = numeric[1].n, numeric[#numeric].n
            if #numeric ~= (hi - lo + 1) then goto continue end

            -- mark originals for skipping
            for _, item in ipairs(numeric) do
                skip[item.b] = true
            end

            local keys_lo = fmt_key(numeric[1].b.key, numeric[1].b.keycode)
            local keys_hi = fmt_key(numeric[#numeric].b.key, numeric[#numeric].b.keycode)
            local mod      = mod_str(mask)
            local bind_str = mod ~= "" and (mod .. " + " .. keys_lo .. "–" .. keys_hi)
                                        or (keys_lo .. "–" .. keys_hi)
            local desc
            if disp == "split-workspace" then
                desc = string.format("Switch to workspace %d–%d", lo, hi)
            else
                desc = string.format("Move window → workspace %d–%d (silent)", lo, hi)
            end

            table.insert(extra, {
                cat      = "Workspace",
                bind_str = bind_str,
                desc     = desc,
            })

            ::continue::
        end
    end

    return skip, extra
end

----------------------------------------------------------------------
-- Collapse arrow groups (4-dir and 2-dir)
----------------------------------------------------------------------

local function collapse_arrow_groups(raw)
    local skip  = {}
    local extra = {}

    -- group by (dispatcher, modmask)
    local groups = {}
    for _, b in ipairs(raw) do
        local is4 = DISPATCHERS_4[b.dispatcher] ~= nil
        local is2 = DISPATCHERS_2[b.dispatcher] ~= nil
        if is4 or is2 then
            local key = b.dispatcher .. "\0" .. tostring(b.modmask)
            groups[key] = groups[key] or { dispatcher = b.dispatcher, modmask = b.modmask, members = {} }
            table.insert(groups[key].members, b)
        end
    end

    for _, g in pairs(groups) do
        local disp    = g.dispatcher
        local mask    = g.modmask
        local members = g.members

        -- map direction → bind
        local dir_map = {}
        for _, m in ipairs(members) do
            local d = canonical_dir(m.arg)
            if d then dir_map[d] = m end
        end

        local mod = mod_str(mask)

        if DISPATCHERS_4[disp] and
           dir_map["←"] and dir_map["→"] and dir_map["↑"] and dir_map["↓"] then

            for _, m in ipairs(members) do
                if canonical_dir(m.arg) then skip[m] = true end
            end

            local bind_str = mod ~= "" and (mod .. " + ↑↓←→") or "↑↓←→"
            local desc     = DISPATCHERS_4[disp] .. " ↑↓←→"
            local cat      = CAT_MAP[disp] or "Other"
            table.insert(extra, { cat = cat, bind_str = bind_str, desc = desc })

        elseif DISPATCHERS_2[disp] and dir_map["←"] and dir_map["→"] then

            for _, m in ipairs(members) do
                if canonical_dir(m.arg) then skip[m] = true end
            end

            local bind_str = mod ~= "" and (mod .. " + ←→") or "←→"
            table.insert(extra, {
                cat      = "Monitor",
                bind_str = bind_str,
                desc     = "Move window ←→ monitor (silent)",
            })
        end
    end

    return skip, extra
end

----------------------------------------------------------------------
-- Build entries
----------------------------------------------------------------------

function GetEntries()
    local raw = load_binds()

    local ws_skip,    ws_extra    = collapse_workspace_groups(raw)
    local arrow_skip, arrow_extra = collapse_arrow_groups(raw)

    -- merge skip sets
    local skip = {}
    for b in pairs(ws_skip)    do skip[b] = true end
    for b in pairs(arrow_skip) do skip[b] = true end

    local entries = {}

    -- real (non-skipped) binds
    for _, b in ipairs(raw) do
        if not skip[b] then
            local desc = fmt_action(b.dispatcher, b.arg)
            if desc ~= nil then
                local cat      = CAT_MAP[b.dispatcher] or "Other"
                local key      = fmt_key(b.key, b.keycode)
                local mods     = mod_str(b.modmask)
                local bind_str = mods ~= "" and (mods .. " + " .. key) or key

                table.insert(entries, {
                    Text    = bind_str,
                    Subtext = cat .. " → " .. desc,
                    Value   = b.dispatcher .. "\31" .. b.arg,
                    Actions = { activate = "lua:RunBind" },
                })
            end
        end
    end

    -- collapsed extras
    for _, e in ipairs(ws_extra) do
        table.insert(entries, {
            Text    = e.bind_str,
            Subtext = e.cat .. " → " .. e.desc,
            Value   = "__grouped__",
            Actions = { activate = "lua:GroupedEntry" },
        })
    end
    for _, e in ipairs(arrow_extra) do
        table.insert(entries, {
            Text    = e.bind_str,
            Subtext = e.cat .. " → " .. e.desc,
            Value   = "__grouped__",
            Actions = { activate = "lua:GroupedEntry" },
        })
    end

    -- sort by category order
    table.sort(entries, function(a, b)
        local ca = a.Subtext:match("^([^→]+)")
        local cb = b.Subtext:match("^([^→]+)")
        return cat_index(trim(ca)) < cat_index(trim(cb))
    end)

    return entries
end