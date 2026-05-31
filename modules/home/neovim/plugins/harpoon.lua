-- ── plugins/harpoon.lua ──────────────────────────────────────────────────────
-- Harpoon solves a specific problem: when you're deep in a feature you have
-- 3-5 files you constantly switch between. Telescope is great for *finding*
-- files, but Harpoon gives you instant numbered slots for the files you're
-- *actively working on* right now.
--
-- Workflow:
--   1. Open a file you're working on → <leader>a to add it to Harpoon
--   2. Open another file → <leader>a again
--   3. Now <C-1>/<C-2>/... teleports instantly between them
--   4. <C-e> opens the Harpoon list to reorder or remove entries
--
-- TIP: Think of it like browser tabs for your current task — not your whole
-- project, just the 3-5 files you need *right now*.
-- ─────────────────────────────────────────────────────────────────────────────

local harpoon = require('harpoon')
harpoon:setup({
  settings = {
    save_on_toggle    = true,   -- save list when you close the menu
    sync_on_ui_close  = true,
  },
})

local map = function(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { silent = true, desc = desc })
end

-- Add current file to harpoon list
map('<leader>a', function() harpoon:list():add() end, 'Harpoon: add file')

-- Toggle the harpoon quick menu
map('<C-e>', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, 'Harpoon: menu')

-- Jump to specific slots — <C-1> through <C-4>
-- TIP: these are instant, no fuzzy search needed — just muscle memory
map('<C-1>', function() harpoon:list():select(1) end, 'Harpoon: file 1')
map('<C-2>', function() harpoon:list():select(2) end, 'Harpoon: file 2')
map('<C-3>', function() harpoon:list():select(3) end, 'Harpoon: file 3')
map('<C-4>', function() harpoon:list():select(4) end, 'Harpoon: file 4')

-- Cycle through harpoon list (prev/next)
map('<C-S-p>', function() harpoon:list():prev() end, 'Harpoon: previous')
map('<C-S-n>', function() harpoon:list():next() end, 'Harpoon: next')
