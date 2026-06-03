Name = "aliases"
NamePretty = "Zsh Aliases"
Icon = "utilities-terminal"
Cache = false
SearchName = true

-- ─────────────────────────────────────────────────────────────
-- Category classifier (PORTED FROM YOUR PYTHON)
-- ─────────────────────────────────────────────────────────────

local CATEGORY_ORDER = {
    "Nix & Scripts",
    "Python",
    "Editors",
    "Files & Viewing",
    "Navigation",
    "System",
    "Containers",
    "Network",
    "Archives",
    "Miscellaneous",
    "Git",
}

local function categorise(name, cmd)
    local n = string.lower(name)
    local c = string.lower(cmd)
    local b = n .. " " .. c

    -- Git
    if string.find(c, "^git ") then
        return "Git"
    end
    if string.match(n, "^g[a-z][a-z]?$") and string.find(c, "git") then
        return "Git"
    end

    -- Nix & scripts
    if string.find(b, "nix") or string.find(n, "^my%-") then
        return "Nix & Scripts"
    end

    -- Python
    if string.find(b, "python") or string.find(b, "pip ") or
       string.find(b, "venv") or n == "py" then
        return "Python"
    end

    -- Editors
    if string.find(b, "vim") or string.find(b, "nvim") or
       string.find(b, "codium") or string.find(b, "code ") or
       string.find(b, "nano") or string.find(b, "hx ") then
        return "Editors"
    end

    -- Files & viewing
    if string.find(b, "eza") or string.find(b, " ls") or
       string.find(b, "ll ") or string.find(b, "la ") or
       string.find(b, "tree") or string.find(b, "icat") or
       string.find(b, "bat ") or string.find(b, "dsize") or
       string.find(b, "psize") or string.find(b, "gtrash") then
        return "Files & Viewing"
    end

    -- Navigation
    if string.find(b, "cd") or string.find(b, "z ") or
       string.find(b, "zoxide") or string.find(b, "pwd") then
        return "Navigation"
    end

    -- Containers
    if string.find(b, "docker") or string.find(b, "kubectl") or
       string.find(b, "helm") or string.find(b, "podman") then
        return "Containers"
    end

    -- System
    if string.find(b, "sudo") or string.find(b, "shutdown") or
       string.find(b, "reboot") or string.find(b, "systemctl") or
       string.find(b, "journalctl") then
        return "System"
    end

    -- Network
    if string.find(b, "ssh ") or string.find(b, "curl") or
       string.find(b, "wget") or string.find(b, "ping") or
       string.find(b, "nmap") or string.find(b, "netstat") then
        return "Network"
    end

    -- Archives
    if string.find(b, "tar") or string.find(b, "zip") or
       string.find(b, "unzip") or string.find(b, "7z") or
       string.find(b, "rar") then
        return "Archives"
    end

    return "Miscellaneous"
end

-- ─────────────────────────────────────────────────────────────
-- Fetch aliases
-- ─────────────────────────────────────────────────────────────

local function fetch_aliases()
    local aliases = {}

    local handle = io.popen(
        "zsh -c 'source \"$HOME/.zshrc\" 2>/dev/null || true; alias'"
    )

    if not handle then
        return aliases
    end

    for line in handle:lines() do
        local name, cmd = line:match("^([^=]+)=(.+)$")
        if name and cmd then
            cmd = cmd:gsub("^['\"]", ""):gsub("['\"]$", "")
            table.insert(aliases, { name = name, cmd = cmd })
        end
    end

    handle:close()
    return aliases
end

-- ─────────────────────────────────────────────────────────────
-- Build Walker entries (grouped like your fzf version)
-- ─────────────────────────────────────────────────────────────

function GetEntries()
    local aliases = fetch_aliases()
    local groups = {}

    -- init groups
    for _, cat in ipairs(CATEGORY_ORDER) do
        groups[cat] = {}
    end

    -- categorize
    for _, a in ipairs(aliases) do
        local cat = categorise(a.name, a.cmd)
        if not groups[cat] then
            groups[cat] = {}
        end
        table.insert(groups[cat], a)
    end

    local results = {}

    for _, cat in ipairs(CATEGORY_ORDER) do
        local items = groups[cat]

        table.sort(items, function(a, b)
            return a.name:lower() < b.name:lower()
        end)

        for _, a in ipairs(items) do
            table.insert(results, {
                Text = a.name,
                Subtext = cat .. "  →  " .. a.cmd,
                Value = a.name,

                Actions = {
                    copyAlias = "wl-copy '%VALUE%'",
                    runAlias = "kitty sh -ic '%VALUE%; echo; exec $SHELL'"
                },

                Icon = "utilities-terminal",
            })
        end
    end

    return results
end