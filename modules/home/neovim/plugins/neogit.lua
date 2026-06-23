-- ── plugins/neogit.lua ───────────────────────────────────────────────────────
-- Neogit is a git status buffer that behaves like Magit (Emacs) — it's the
-- closest thing to VSCode's Source Control panel, but it's a normal nvim
-- buffer rather than a sidebar, so every action is just a keypress on the
-- line/section under your cursor. No mouse, ever.
--
-- TIP: inside the Neogit status buffer (after opening with <leader>gg):
--   <Tab>     expand/collapse a section (e.g. see the diff under "Unstaged")
--   s         stage the file/hunk under cursor
--   u         unstage
--   S / U     stage/unstage ALL
--   c c       open commit prompt (press it twice: c = commit menu, c = commit)
--   p p       push (p = push menu, p = push to upstream)
--   P p       pull
--   l l       open log (the commit graph — shows local vs remote divergence)
--   b b       branch menu (create/checkout/delete)
--   x         discard change under cursor
--   q         close
--
-- The log view (`l l` from status, or <leader>gl directly) renders the
-- branch graph — this is your "visual git tree", equivalent to VSCode's
-- Source Control graph view.
-- ─────────────────────────────────────────────────────────────────────────────

local neogit = require('neogit')

neogit.setup({
  disable_signs = false,
  disable_hint = false,
  disable_commit_confirmation = false,
  disable_builtin_notifications = false,

  graph_style = 'unicode',     -- nicer-looking commit graph in the log view

  integrations = {
    telescope = true,           -- branch/commit pickers use Telescope, not a raw list
    diffview = true,             -- 'd' on a diff opens diffview instead of inline diff
  },

  commit_editor = {
    kind = 'tab',
  },
  commit_select_view = {
    kind = 'tab',
  },
  log_view = {
    kind = 'tab',
  },
  status = {
    recent_commit_count = 10,
  },
})

-- ── diffview.nvim ────────────────────────────────────────────────────────────
-- Side-by-side diff viewer. Neogit opens this automatically for diffs (via
-- the integration above), but these keymaps let you jump straight to it.
--
-- TIP: inside a diffview:
--   <Tab> / <S-Tab>   next/previous changed file
--   ]c / [c           next/previous hunk (matches your gitsigns ]c/[c below)
--   q  or  :DiffviewClose
require('diffview').setup({
  enhanced_diff_hl = true,
})

-- ── Keymaps ──────────────────────────────────────────────────────────────────
-- Grouped under <leader>g alongside your existing gitsigns binds
-- (<leader>gs/gr/gb/gd/gp in plugins/ui.lua) — same prefix, different letters.
local map = function(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { silent = true, desc = desc })
end

map('<leader>gg', neogit.open,                                   'Git: status (Neogit)')
map('<leader>gl', function() neogit.open({ 'log' }) end,         'Git: log graph')
map('<leader>gc', function() neogit.open({ 'commit' }) end,      'Git: commit')
map('<leader>gP', function() neogit.open({ 'push' }) end,        'Git: push')
map('<leader>gB', function() neogit.open({ 'branch' }) end,      'Git: branch menu')

map('<leader>gD', '<cmd>DiffviewOpen<CR>',                       'Git: diff view (working tree)')
map('<leader>gH', '<cmd>DiffviewFileHistory %<CR>',              'Git: file history (current file)')
map('<leader>gX', '<cmd>DiffviewClose<CR>',                      'Git: close diff view')
