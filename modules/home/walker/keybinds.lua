Name = "keybinds"
NamePretty = "Hyprland Keybinds"
Icon = "input-keyboard"
Cache = false
SearchName = true

----------------------------------------------------------------------
-- How this menu gets its data (Hyprland 0.55+ Lua config)
----------------------------------------------------------------------
-- With the Lua config provider, `hyprctl binds -j` reports EVERY hl.bind()
-- as dispatcher "__lua" with an opaque registry id as its arg (see
-- hlBind() in Hyprland's LuaBindingsToplevel.cpp). The real action is a
-- closure and cannot be introspected, so the old "read dispatcher/arg from
-- hyprctl" approach can no longer work.
--
-- Instead we execute ~/.config/hypr/keybinds.lua in a sandbox where `hl` is
-- a recording stub. Every hl.bind() is captured together with the
-- hl.dsp.* call it was given, which lets us:
--   * describe / categorise / group binds using the NEW dispatcher names
--     (hl.dsp.window.close, hl.dsp.focus, ...), and
--   * run a bind from this menu with the documented
--     `hyprctl dispatch 'hl.dsp.<...>'` form.
-- Loops (e.g. the workspace 1-10 binds) and function binds work because the
-- file is really executed, not text-parsed.

local SMW_MODULE = "plugins.split-monitor-workspaces"
local SEP        = "\31"

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

local CAT_ORDER = {
    "Launch", "Window", "Focus", "Resize", "Float",
    "Workspace", "Monitor", "Submap", "System", "Other",
}

local function cat_index(cat)
    for i, v in ipairs(CAT_ORDER) do
        if v == cat then return i end
    end
    return 999
end

local function trim(s)
    return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function oneline(s)
    return trim((tostring(s):gsub("%s+", " ")))
end

local function shq(s)
    return "'" .. (tostring(s):gsub("'", "'\\''")) .. "'"
end

local function sorted_keys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

----------------------------------------------------------------------
-- Lua value serialiser (used to rebuild hl.dsp.* expressions)
----------------------------------------------------------------------

local function lua_str(s)
    s = s:gsub("\\", "\\\\")
    s = s:gsub('"', '\\"')
    s = s:gsub("\n", "\\n")
    s = s:gsub("\r", "\\r")
    return '"' .. s .. '"'
end

local ser
ser = function(v)
    local t = type(v)
    if t == "string" then
        return lua_str(v)
    elseif t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "table" then
        local parts, seen = {}, {}
        for i, x in ipairs(v) do
            parts[#parts + 1] = ser(x)
            seen[i] = true
        end
        local keys = {}
        for k in pairs(v) do
            if not seen[k] then keys[#keys + 1] = k end
        end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        for _, k in ipairs(keys) do
            local ks = (type(k) == "string" and k:match("^[%a_][%w_]*$"))
                and k or ("[" .. ser(k) .. "]")
            parts[#parts + 1] = ks .. " = " .. ser(v[k])
        end
        if #parts == 0 then return "{}" end
        return "{ " .. table.concat(parts, ", ") .. " }"
    end
    return "nil"
end

----------------------------------------------------------------------
-- Recorded dispatcher calls
----------------------------------------------------------------------
-- A "rec" is one captured call:
--   { ns = "dsp", path = "window.move", args = {...}, n = <arg count> }
--   { ns = "smw", path = "smw.workspace", args = {...}, n = ... }
-- ns "dsp" = Hyprland's own hl.dsp.*; ns "smw" = split-monitor-workspaces.

local REC_MT = {}

local function is_rec(v)
    return type(v) == "table" and getmetatable(v) == REC_MT
end

local function make_rec(ns, path, ...)
    return setmetatable({
        ns   = ns,
        path = path,
        args = { ... },
        n    = select("#", ...),
    }, REC_MT)
end

local function rec_expr(r)
    local parts = {}
    for i = 1, r.n do parts[i] = ser(r.args[i]) end
    local a = table.concat(parts, ", ")
    if r.ns == "smw" then
        return 'require("' .. SMW_MODULE .. '").' .. r.path:sub(5) .. "(" .. a .. ")"
    end
    return "hl.dsp." .. r.path .. "(" .. a .. ")"
end

-- hl.dsp.<ns>.<fn>(...) -> rec ; a node can be indexed deeper or called
local function make_dsp_node(path)
    return setmetatable({}, {
        __index = function(_, k)
            return make_dsp_node(path == "" and k or (path .. "." .. k))
        end,
        __call = function(_, ...)
            return make_rec("dsp", path, ...)
        end,
    })
end

----------------------------------------------------------------------
-- Modifier / key formatting
----------------------------------------------------------------------

local MOD_NAMES = {
    SUPER = "Super", WIN = "Super", LOGO = "Super", MOD4 = "Super", META = "Super",
    SHIFT = "Shift", CTRL = "Ctrl", CONTROL = "Ctrl",
    ALT = "Alt", MOD1 = "Alt",
    CAPS = "Caps", MOD2 = "Mod2", MOD3 = "Mod3", MOD5 = "Mod5",
}
local MOD_ORDER = { "Super", "Shift", "Ctrl", "Alt", "Caps", "Mod2", "Mod3", "Mod5" }

-- keys are matched case-insensitively (Hyprland resolves keysyms that way)
local KEY_MAP = {
    ["return"] = "Enter", comma = ",", period = ".", semicolon = ";",
    space = "Space", escape = "Esc",
    left = "←", right = "→", up = "↑", down = "↓",
    xf86audioraisevolume  = "Vol↑",   xf86audiolowervolume = "Vol↓",
    xf86audiomute         = "Mute",   xf86audioplay        = "Play/Pause",
    xf86audionext         = "Next",   xf86audioprev        = "Prev",
    xf86audiostop         = "Stop",
    xf86monbrightnessup   = "Bright↑", xf86monbrightnessdown = "Bright↓",
    mouse_up    = "Scroll↑", mouse_down  = "Scroll↓",
    ["mouse:272"] = "LClick", ["mouse:273"] = "RClick",
}

local KEYCODE_MAP = { [233] = "Bright↑", [232] = "Bright↓" }

local ARROW_KEYS = { left = true, right = true, up = true, down = true }

local function fmt_key(tok)
    local lc = tok:lower()
    if KEY_MAP[lc] then return KEY_MAP[lc] end
    local code = lc:match("^code:(%d+)$")
    if code then
        return KEYCODE_MAP[tonumber(code)] or ("key:" .. code)
    end
    local sw = tok:match("^switch:(.+)$")
    if sw then return sw end
    if #tok == 1 then return tok:upper() end
    return tok
end

-- "SUPER+SHIFT+Return" -> mods = "Super + Shift", key = "Enter", key_lc = "return"
local function parse_keys(raw)
    local mods, keys, keys_lc = {}, {}, {}
    for tok in (raw .. "+"):gmatch("([^+]*)%+") do
        tok = trim(tok)
        if tok ~= "" then
            local m = MOD_NAMES[tok:upper()]
            if m and #keys == 0 then
                mods[m] = true
            else
                keys[#keys + 1]       = fmt_key(tok)
                keys_lc[#keys_lc + 1] = tok:lower()
            end
        end
    end
    local ml = {}
    for _, name in ipairs(MOD_ORDER) do
        if mods[name] then ml[#ml + 1] = name end
    end
    return table.concat(ml, " + "), table.concat(keys, " + "), keys_lc[1] or ""
end

local function join_bind(mods, key)
    return mods ~= "" and (mods .. " + " .. key) or key
end

----------------------------------------------------------------------
-- Direction helpers
----------------------------------------------------------------------

local function canonical_dir(arg)
    local a = trim(string.lower(tostring(arg or "")))
    if a == "l" or a == "left"         then return "←" end
    if a == "r" or a == "right"        then return "→" end
    if a == "u" or a == "up"           then return "↑" end
    if a == "d" or a == "down"         then return "↓" end
    if a == "prev" or a == "-1"        then return "←" end
    if a == "next" or a == "+1"        then return "→" end
    return nil
end

local function dir_from_xy(x, y)
    x, y = tonumber(x) or 0, tonumber(y) or 0
    if x < 0 then return "←" end
    if x > 0 then return "→" end
    if y < 0 then return "↑" end
    if y > 0 then return "↓" end
    return nil
end

local function as_table(v)
    return type(v) == "table" and v or {}
end

-- numeric-only workspace argument (so "+1" / "empty" are never grouped)
local function ws_number(v)
    local s = tostring(v)
    if s:match("^%d+$") then return tonumber(s) end
    return nil
end

----------------------------------------------------------------------
-- Categories (keyed by the NEW hl.dsp.* paths)
----------------------------------------------------------------------

local CAT_MAP = {
    ["exec_cmd"]                     = "Launch",
    ["exec_raw"]                     = "Launch",
    ["window.close"]                 = "Window",
    ["window.kill"]                  = "Window",
    ["window.fullscreen"]            = "Window",
    ["window.fullscreen_state"]      = "Window",
    ["window.float"]                 = "Window",
    ["window.pin"]                   = "Window",
    ["window.pseudo"]                = "Window",
    ["window.center"]                = "Window",
    ["window.cycle_next"]            = "Window",
    ["window.tag"]                   = "Window",
    ["window.signal"]                = "Window",
    ["layout"]                       = "Window",
    ["window.swap"]                  = "Focus",
    ["window.drag"]                  = "Float",
    ["workspace.toggle_special"]     = "Workspace",
    ["workspace.rename"]             = "Workspace",
    ["workspace.move"]               = "Monitor",
    ["workspace.swap_monitors"]      = "Monitor",
    ["smw.workspace"]                = "Workspace",
    ["smw.move_to_workspace"]        = "Workspace",
    ["smw.move_to_workspace_silent"] = "Workspace",
    ["smw.cycle_workspaces"]         = "Workspace",
    ["smw.change_monitor"]           = "Monitor",
    ["smw.change_monitor_silent"]    = "Monitor",
    ["smw.grab_rogue_windows"]       = "Monitor",
    ["submap"]                       = "Submap",
    ["dpms"]                         = "System",
    ["exit"]                         = "System",
    ["reload_config"]                = "System",
}

local function category(r)
    local p, t = r.path, as_table(r.args[1])
    if p == "window.move" then
        if t.direction ~= nil then return "Focus" end
        if t.x ~= nil then return "Float" end
        if t.monitor ~= nil then return "Monitor" end
        return "Window"
    elseif p == "window.resize" then
        return "Resize"
    elseif p == "focus" then
        if t.workspace ~= nil then return "Workspace" end
        if t.monitor ~= nil then return "Monitor" end
        return "Focus"
    elseif p:match("^group%.") then
        return "Window"
    end
    return CAT_MAP[p] or "Other"
end

----------------------------------------------------------------------
-- Action descriptions
----------------------------------------------------------------------

local function describe(r)
    local p, a = r.path, r.args[1]
    local t = as_table(a)

    if p == "exec_cmd" or p == "exec_raw" then
        local s = oneline(a or "")
        local rules = r.args[2]
        if type(rules) == "table" then
            local ks = sorted_keys(rules)
            if #ks > 0 then s = s .. "  [" .. table.concat(ks, ", ") .. "]" end
        end
        return s

    elseif p == "window.close" then
        return "Close window"
    elseif p == "window.kill" then
        return "Kill window"
    elseif p == "window.fullscreen" then
        return t.mode == "maximized" and "Maximize" or "Fullscreen"
    elseif p == "window.fullscreen_state" then
        return "Fullscreen (custom state)"
    elseif p == "window.float" then
        local act = t.action
        if act == nil or act == "toggle" then return "Toggle float" end
        if act == "set" or act == "enable" or act == "on" then return "Set floating" end
        return "Set tiled"
    elseif p == "window.pin" then
        return "Pin window"
    elseif p == "window.pseudo" then
        return "Toggle pseudotile"
    elseif p == "window.center" then
        return "Center window"
    elseif p == "layout" then
        return "Layout: " .. tostring(a or "")
    elseif p == "window.cycle_next" then
        return "Cycle window " .. (t.next == false and "← prev" or "→ next")
    elseif p == "window.bring_to_top" or p == "window.alter_zorder" then
        return nil -- companion to cycle_next, not interesting on its own

    elseif p == "window.move" then
        if t.direction ~= nil then
            local d = canonical_dir(t.direction)
            return "Move window " .. (d or tostring(t.direction))
        elseif t.workspace ~= nil then
            return "Move window → workspace " .. tostring(t.workspace) ..
                   (t.follow == false and " (silent)" or "")
        elseif t.monitor ~= nil then
            return "Move window → monitor " .. tostring(t.monitor)
        elseif t.x ~= nil or t.y ~= nil then
            if t.relative then
                local dx, dy = tonumber(t.x) or 0, tonumber(t.y) or 0
                local arrows = (dx > 0 and "→" or dx < 0 and "←" or "") ..
                               (dy > 0 and "↓" or dy < 0 and "↑" or "")
                return "Move floating " .. arrows
            end
            return "Move floating to " .. tostring(t.x) .. ", " .. tostring(t.y)
        end
        return "Move window"

    elseif p == "window.resize" then
        if t.x ~= nil or t.y ~= nil then
            local dx, dy = tonumber(t.x) or 0, tonumber(t.y) or 0
            if t.relative then
                local parts = {}
                if dx ~= 0 then table.insert(parts, (dx > 0 and "→" or "←") .. " " .. math.abs(dx) .. "px") end
                if dy ~= 0 then table.insert(parts, (dy > 0 and "↓" or "↑") .. " " .. math.abs(dy) .. "px") end
                return "Resize  " .. table.concat(parts, "  ")
            end
            return "Resize to " .. dx .. "×" .. dy .. "px"
        end
        return "Resize window (mouse drag)"
    elseif p == "window.drag" then
        return "Move window (mouse drag)"

    elseif p == "focus" then
        if t.direction ~= nil then
            local d = canonical_dir(t.direction)
            return "Move focus " .. (d or tostring(t.direction))
        elseif t.workspace ~= nil then
            return "Switch to workspace " .. tostring(t.workspace)
        elseif t.monitor ~= nil then
            return "Focus monitor " .. tostring(t.monitor)
        elseif t.window ~= nil then
            return "Focus window " .. tostring(t.window)
        end
        return "Focus " .. trim(ser(t):gsub("^{ ?", ""):gsub(" ?}$", ""))

    elseif p == "window.swap" then
        if t.direction ~= nil then
            return "Swap window " .. (canonical_dir(t.direction) or tostring(t.direction))
        end
        return "Swap window"
    elseif p == "group.toggle" then
        return "Toggle group"
    elseif p == "group.next" then
        return "Group: next window"
    elseif p == "group.prev" then
        return "Group: previous window"

    elseif p == "workspace.toggle_special" then
        return "Toggle special workspace " .. tostring(a or "")

    elseif p == "smw.workspace" then
        return "Switch to workspace " .. tostring(a or "")
    elseif p == "smw.move_to_workspace" then
        return "Move window → workspace " .. tostring(a or "")
    elseif p == "smw.move_to_workspace_silent" then
        return "Move window → workspace " .. tostring(a or "") .. " (silent)"
    elseif p == "smw.cycle_workspaces" then
        local sym = (a == "+1" or a == "next") and "→" or "←"
        return "Cycle workspaces " .. sym
    elseif p == "smw.change_monitor" or p == "smw.change_monitor_silent" then
        local sil = p == "smw.change_monitor_silent" and " (silent)" or ""
        local d = canonical_dir(a)
        if d then return "Move window " .. d .. " monitor" .. sil end
        return "Move window to " .. tostring(a or "") .. " monitor" .. sil
    elseif p == "smw.grab_rogue_windows" then
        return "Grab windows orphaned by disconnected monitor"

    elseif p == "dpms" then
        return "Display power: " .. tostring(t.action or "toggle") ..
               (t.monitor and (" " .. tostring(t.monitor)) or "")
    elseif p == "submap" then
        if a == "reset" then return "Exit submap" end
        return "Enter submap " .. tostring(a or "")
    elseif p == "reload_config" then
        return "Reload config"
    elseif p == "exit" then
        return "Exit Hyprland"
    end

    local parts = {}
    for i = 1, r.n do parts[i] = ser(r.args[i]) end
    return trim(p .. " " .. table.concat(parts, ", "))
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

function NotRunnable(value, args)
    os.execute(
        "notify-send 'Keybind not runnable' " ..
        "'This keybind needs a live key or mouse press and cannot be triggered from the menu.'"
    )
end

-- value = "<dispatch|eval>\31<lua expression>"
--   dispatch -> hyprctl dispatch 'hl.dsp.<...>'          (hl.dispatch(<expr>))
--   eval     -> hyprctl eval '<lua statements>'          (multi-step / plugin binds)
function RunBind(value, args)
    local mode, expr = value:match("^(.-)\31(.*)$")
    if not mode or mode == "" or expr == "" then return end
    os.execute(string.format("hyprctl %s %s >/dev/null 2>&1 &", mode, shq(expr)))
end

----------------------------------------------------------------------
-- Load binds: run ~/.config/hypr/keybinds.lua against a recording `hl`
----------------------------------------------------------------------

local function keybinds_path()
    local cfg = os.getenv("XDG_CONFIG_HOME")
    if not cfg or cfg == "" then cfg = (os.getenv("HOME") or "") .. "/.config" end
    return cfg .. "/hypr/keybinds.lua"
end

local function load_binds()
    local path = keybinds_path()
    local f = io.open(path, "r")
    if not f then return nil, "Cannot open " .. path end
    local src = f:read("*a")
    f:close()

    local binds = {}
    local state = { submap = "", capture = nil, order = 0 }

    local function noop() end

    -- smw (split-monitor-workspaces) stub: factories return recs; calls made
    -- from inside a function bind are captured as direct actions.
    local smw = setmetatable({}, {
        __index = function(_, name)
            if name == "get_amount_of_workspaces" then return function() return 10 end end
            if name == "setup" then return noop end
            return function(...)
                local r = make_rec("smw", "smw." .. name, ...)
                if state.capture then
                    r.direct = true
                    table.insert(state.capture, r)
                end
                return r
            end
        end,
    })

    local hl = setmetatable({}, {
        __index = function() return noop end, -- hl.config/on/env/timer/get_*... -> no-op
    })
    hl.dsp = make_dsp_node("")

    function hl.bind(keys, action, opts)
        opts = type(opts) == "table" and opts or {}
        state.order = state.order + 1
        local b = {
            raw     = tostring(keys),
            submap  = state.submap,
            actions = {},
            opts    = opts,
            order   = state.order,
        }
        if is_rec(action) then
            b.actions = { action }
        elseif type(action) == "function" then
            local cap = {}
            state.capture = cap
            pcall(action)
            state.capture = nil
            b.actions = cap
            b.is_fn   = true
        end
        table.insert(binds, b)
        return {
            unbind = function() b.removed = true end,
            remove = function() b.removed = true end,
        }
    end

    function hl.unbind(keys)
        for _, b in ipairs(binds) do
            if b.raw == tostring(keys) and b.submap == state.submap then b.removed = true end
        end
    end

    function hl.dispatch(r)
        if state.capture and is_rec(r) then table.insert(state.capture, r) end
    end

    -- hl.define_submap(name, [reset], fn)
    function hl.define_submap(name, a, b)
        local fn = type(a) == "function" and a or b
        local prev = state.submap
        state.submap = tostring(name)
        if type(fn) == "function" then pcall(fn) end
        state.submap = prev
    end

    local env = {
        hl = hl,
        require = function(mod)
            if tostring(mod):find("split-monitor-workspaces", 1, true) then return smw end
            return setmetatable({}, { __index = function() return noop end })
        end,
        pairs = pairs, ipairs = ipairs, next = next, select = select,
        type = type, tostring = tostring, tonumber = tonumber,
        pcall = pcall, error = error, unpack = unpack or table.unpack,
        string = string, table = table, math = math,
        print = noop,
        os = { getenv = os.getenv, date = os.date, time = os.time },
        package = { path = "", loaded = {} },
    }
    env._G = env

    local chunk, err
    if setfenv then
        chunk, err = loadstring(src, "=keybinds.lua")
        if chunk then setfenv(chunk, env) end
    else
        chunk, err = load(src, "=keybinds.lua", "t", env)
    end
    if not chunk then return nil, "Parse error: " .. tostring(err) end

    local ok, rerr = pcall(chunk)
    if not ok and #binds == 0 then return nil, "Error running keybinds.lua: " .. tostring(rerr) end

    local live = {}
    for _, b in ipairs(binds) do
        if not b.removed then table.insert(live, b) end
    end
    return live
end

----------------------------------------------------------------------
-- Turn raw binds into display entries
----------------------------------------------------------------------

local function make_entries(raw_binds)
    local entries = {}
    for _, b in ipairs(raw_binds) do
        local mods, key, key_lc = parse_keys(b.raw)
        local e = {
            mods    = mods,
            key     = key,
            key_lc  = key_lc,
            submap  = b.submap,
            actions = b.actions,
            order   = b.order,
            main    = (#b.actions == 1) and b.actions[1] or nil,
        }

        -- description + category
        local descs = {}
        for _, r in ipairs(b.actions) do
            local d = describe(r)
            if d ~= nil then descs[#descs + 1] = d end
        end
        local explicit = b.opts.description or b.opts.desc
        if explicit and explicit ~= "" then
            e.desc = tostring(explicit)
        elseif #b.actions == 0 then
            e.desc = "Custom Lua function"
        elseif #descs > 0 then
            e.desc = table.concat(descs, "; ")
        end

        e.cat = (#b.actions > 0) and category(b.actions[1]) or "Other"
        if e.submap ~= "" and e.desc then
            e.cat  = "Submap"
            e.desc = "[" .. e.submap .. "] " .. e.desc
        end

        table.insert(entries, e)
    end
    return entries
end

----------------------------------------------------------------------
-- Collapse workspace groups (sequential numeric, e.g. 1–10)
----------------------------------------------------------------------

local WS_LABEL = {
    switch      = "Switch to workspace %d–%d",
    move        = "Move window → workspace %d–%d",
    move_silent = "Move window → workspace %d–%d (silent)",
}

local function ws_info(r)
    local p, a = r.path, r.args[1]
    local t = as_table(a)
    if p == "smw.workspace" then
        return "switch", ws_number(a)
    elseif p == "smw.move_to_workspace" then
        return "move", ws_number(a)
    elseif p == "smw.move_to_workspace_silent" then
        return "move_silent", ws_number(a)
    elseif p == "focus" and t.workspace ~= nil then
        return "switch", ws_number(t.workspace)
    elseif p == "window.move" and t.workspace ~= nil then
        return (t.follow == false) and "move_silent" or "move", ws_number(t.workspace)
    end
    return nil
end

local function collapse_workspace_groups(entries)
    local skip, extra = {}, {}
    local groups, gorder = {}, {}

    for _, e in ipairs(entries) do
        if e.main then
            local kind, n = ws_info(e.main)
            if kind and n then
                local gk = kind .. "\0" .. e.mods .. "\0" .. e.submap
                if not groups[gk] then
                    groups[gk] = { kind = kind, mods = e.mods, submap = e.submap, items = {} }
                    table.insert(gorder, gk)
                end
                table.insert(groups[gk].items, { n = n, e = e })
            end
        end
    end

    for _, gk in ipairs(gorder) do
        local g = groups[gk]
        local items = g.items
        table.sort(items, function(x, y) return x.n < y.n end)

        local lo, hi = items[1].n, items[#items].n
        if #items >= 3 and #items == (hi - lo + 1) then
            local first_order = items[1].e.order
            for _, it in ipairs(items) do
                skip[it.e] = true
                if it.e.order < first_order then first_order = it.e.order end
            end

            local bind_str = join_bind(g.mods, items[1].e.key .. "–" .. items[#items].e.key)
            local desc = string.format(WS_LABEL[g.kind], lo, hi)
            local cat  = "Workspace"
            if g.submap ~= "" then
                cat  = "Submap"
                desc = "[" .. g.submap .. "] " .. desc
            end
            table.insert(extra, { cat = cat, bind_str = bind_str, desc = desc, order = first_order })
        end
    end

    return skip, extra
end

----------------------------------------------------------------------
-- Collapse arrow groups (4-dir and 2-dir)
----------------------------------------------------------------------

-- returns: group-kind, direction glyph, label, category, directions needed
local function arrow_info(r)
    local p, a = r.path, r.args[1]
    local t = as_table(a)
    if p == "focus" and t.direction ~= nil then
        return "focus", canonical_dir(t.direction), "Move focus", "Focus", 4
    elseif p == "window.move" and t.direction ~= nil then
        return "move_window", canonical_dir(t.direction), "Move window", "Focus", 4
    elseif p == "window.move" and (t.x ~= nil or t.y ~= nil) and t.relative then
        return "move_float", dir_from_xy(t.x, t.y), "Move floating", "Float", 4
    elseif p == "window.resize" and (t.x ~= nil or t.y ~= nil) and t.relative then
        return "resize", dir_from_xy(t.x, t.y), "Resize window", "Resize", 4
    elseif p == "smw.change_monitor" or p == "smw.change_monitor_silent" then
        local d = canonical_dir(a)
        if d == "←" or d == "→" then
            local sil = p == "smw.change_monitor_silent" and " (silent)" or ""
            return p, d, "Move window ←→ monitor" .. sil, "Monitor", 2
        end
    end
    return nil
end

local DIR_ORDER = { "←", "→", "↑", "↓" }

local function collapse_arrow_groups(entries)
    local skip, extra = {}, {}
    local groups, gorder = {}, {}

    for _, e in ipairs(entries) do
        if e.main then
            local gkind, dir, label, cat, need = arrow_info(e.main)
            if gkind and dir then
                local gk = gkind .. "\0" .. e.mods .. "\0" .. e.submap
                if not groups[gk] then
                    groups[gk] = {
                        mods = e.mods, submap = e.submap, label = label,
                        cat = cat, need = need, members = {}, dir_map = {},
                    }
                    table.insert(gorder, gk)
                end
                local g = groups[gk]
                table.insert(g.members, e)
                g.dir_map[dir] = e
            end
        end
    end

    for _, gk in ipairs(gorder) do
        local g, dm = groups[gk], groups[gk].dir_map
        local complete
        if g.need == 4 then
            complete = dm["←"] and dm["→"] and dm["↑"] and dm["↓"]
        else
            complete = dm["←"] and dm["→"]
        end

        if complete then
            local first_order, all_arrows, keys = nil, true, {}
            for _, d in ipairs(DIR_ORDER) do
                local m = dm[d]
                if m then
                    keys[#keys + 1] = m.key
                    if not ARROW_KEYS[m.key_lc] then all_arrows = false end
                end
            end
            for _, m in ipairs(g.members) do
                skip[m] = true
                if not first_order or m.order < first_order then first_order = m.order end
            end

            local key_str
            if all_arrows then
                key_str = (g.need == 4) and "↑↓←→" or "←→"
            else
                key_str = table.concat(keys, " / ")
            end

            local desc = (g.need == 4) and (g.label .. " ↑↓←→") or g.label
            local cat  = g.cat
            if g.submap ~= "" then
                cat  = "Submap"
                desc = "[" .. g.submap .. "] " .. desc
            end
            table.insert(extra, {
                cat = cat, bind_str = join_bind(g.mods, key_str),
                desc = desc, order = first_order or 0,
            })
        end
    end

    return skip, extra
end

----------------------------------------------------------------------
-- Run value for a single (non-grouped) bind
----------------------------------------------------------------------

local function run_value(e)
    local acts = e.actions
    if #acts == 0 then return nil end

    -- interactive mouse dispatchers need a live press
    for _, r in ipairs(acts) do
        local t = as_table(r.args[1])
        if r.path == "window.drag" or
           (r.path == "window.resize" and t.x == nil and t.y == nil) then
            return nil
        end
    end

    if #acts == 1 and acts[1].ns == "dsp" then
        return "dispatch" .. SEP .. rec_expr(acts[1])
    end

    local stmts = {}
    for _, r in ipairs(acts) do
        if r.ns == "dsp" then
            stmts[#stmts + 1] = "hl.dispatch(" .. rec_expr(r) .. ")"
        elseif r.direct then
            stmts[#stmts + 1] = rec_expr(r)           -- smw call made inside a function bind
        else
            stmts[#stmts + 1] = rec_expr(r) .. "()"   -- smw factory -> returns the action closure
        end
    end
    return "eval" .. SEP .. table.concat(stmts, "; ")
end

----------------------------------------------------------------------
-- Build entries
----------------------------------------------------------------------

function GetEntries()
    local raw, err = load_binds()
    if not raw then
        return {
            {
                Text    = "Could not load Hyprland keybinds",
                Subtext = err or "unknown error",
                Value   = "__grouped__",
                Actions = { activate = "lua:NotRunnable" },
            },
        }
    end

    local all = make_entries(raw)

    local ws_skip,    ws_extra    = collapse_workspace_groups(all)
    local arrow_skip, arrow_extra = collapse_arrow_groups(all)

    local rows = {}

    -- real (non-skipped) binds
    for _, e in ipairs(all) do
        if not ws_skip[e] and not arrow_skip[e] and e.desc ~= nil then
            local rv = run_value(e)
            table.insert(rows, {
                cat   = e.cat,
                order = e.order,
                entry = {
                    Text    = join_bind(e.mods, e.key),
                    Subtext = e.cat .. " → " .. e.desc,
                    Value   = rv or "__none__",
                    Actions = { activate = rv and "lua:RunBind" or "lua:NotRunnable" },
                },
            })
        end
    end

    -- collapsed extras
    for _, list in ipairs({ ws_extra, arrow_extra }) do
        for _, x in ipairs(list) do
            table.insert(rows, {
                cat   = x.cat,
                order = x.order,
                entry = {
                    Text    = x.bind_str,
                    Subtext = x.cat .. " → " .. x.desc,
                    Value   = "__grouped__",
                    Actions = { activate = "lua:GroupedEntry" },
                },
            })
        end
    end

    -- sort by category order, then by position in keybinds.lua (stable)
    table.sort(rows, function(a, b)
        local ca, cb = cat_index(a.cat), cat_index(b.cat)
        if ca ~= cb then return ca < cb end
        return a.order < b.order
    end)

    local entries = {}
    for _, r in ipairs(rows) do entries[#entries + 1] = r.entry end
    return entries
end

