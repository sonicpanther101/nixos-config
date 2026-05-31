-- ── plugins/editing.lua ──────────────────────────────────────────────────────

-- ── nvim-surround ────────────────────────────────────────────────────────────
-- Adds operations for surrounding characters (brackets, quotes, tags).
-- TIP examples (in normal mode):
--   `cs"'`        change surrounding " to '      (hello "world" → hello 'world')
--   `cs'<q>`      change surrounding ' to <q>    ('world' → <q>world</q>)
--   `ds"`         delete surrounding "            ("hello" → hello)
--   `ysiw"`       add " around inner word         (hello → "hello")
--   `yss)`        wrap entire line in ()
--   `S"` in visual wrap selection in "
require('nvim-surround').setup()

-- ── Comment.nvim ─────────────────────────────────────────────────────────────
-- TIP: `gcc` toggles a line comment (like Ctrl+/ in VSCode)
--       `gc{motion}` comments a motion  e.g. `gc5j` comments 5 lines down
--       `gbc` toggles a block comment
-- Works correctly per filetype: // in C++, # in Python, -- in Lua, etc.
require('Comment').setup({
  padding = true,   -- add a space after the comment character
  sticky  = true,   -- keep cursor position after commenting
})

-- ── nvim-autopairs ───────────────────────────────────────────────────────────
-- Auto-closes (, [, {, ", ', ` when you type the opening character.
-- Also integrates with cmp so pressing <CR> inside {} adds a blank indented line.
local autopairs = require('nvim-autopairs')
autopairs.setup({
  check_ts = true,   -- use treesitter to understand context
                     -- (e.g. don't pair ' inside a string in Lua)
  ts_config = {
    lua  = { 'string' },   -- don't pair ' in lua strings
    cpp  = { 'string' },
    python = { 'string' },
  },
  -- Don't add pairs when the next character is alphanumeric
  -- (stops `(` becoming `()` when cursor is in the middle of a word)
  fast_wrap = {
    map    = '<M-e>',     -- Alt+e wraps the word to the right of cursor
    chars  = { '{', '[', '(', '"', "'" },
    end_key = '$',
    cursor_pos_before = true,
  },
})

-- Tell cmp to handle autopairs on <CR>
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
local cmp = require('cmp')
cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
