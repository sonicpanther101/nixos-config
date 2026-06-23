-- ── plugins/oil.lua ──────────────────────────────────────────────────────────
-- Oil turns a directory into a normal text buffer — one file/folder per line.
-- There is no tree widget, no mouse interaction, no special UI mode: it's
-- just vim motions applied to a list of names.
--
-- TIP: core mental model
--   rename  → change the text on a line, then :w (or <leader>w below)
--   move    → cut the line (dd), go to destination dir, paste it (p), :w
--   create  → go to end of buffer, type a new line, :w
--             (trailing "/" on the name creates a directory)
--   delete  → delete the line (dd), :w   (oil shows a confirm diff first)
--   copy    → yank the line (yy), paste elsewhere, :w
--
-- Nothing touches disk until you save — oil computes a diff of intended
-- changes and asks you to confirm before applying them.
-- ─────────────────────────────────────────────────────────────────────────────

local oil = require('oil')

oil.setup({
  default_file_explorer = true,  -- `:e .` / `-` open oil instead of netrw

  view_options = {
    show_hidden = true,          -- see dotfiles (toggle with `g.`)
    natural_order = true,
  },

  -- Skip the "are you sure" popup for trivial stuff, but still confirm
  -- destructive changes (delete/move) — same safety net as gtrash elsewhere
  -- in this config.
  skip_confirm_for_simple_edits = false,

  delete_to_trash = true,        -- deletes go through your trash (gtrash-style safety)

  keymaps = {
    ['g?']        = 'actions.show_help',
    ['<CR>']      = 'actions.select',                  -- open file / enter dir
    ['<C-s>']     = 'actions.select_vsplit',
    ['<C-h>']     = false,                              -- don't shadow window-nav
    ['<C-l>']     = false,
    ['<C-t>']     = 'actions.select_tab',
    ['<C-p>']     = 'actions.preview',
    ['<C-c>']     = 'actions.close',
    ['q']         = 'actions.close',                    -- consistent with Trouble's `q`
    ['<BS>']      = 'actions.parent',                   -- go up a directory
    ['-']         = 'actions.parent',
    ['_']         = 'actions.open_cwd',
    ['`']         = 'actions.cd',
    ['gs']        = 'actions.change_sort',
    ['gx']        = 'actions.open_external',
    ['g.']        = 'actions.toggle_hidden',
    ['g\\']       = 'actions.toggle_trash',
  },

  use_default_keymaps = false,   -- we declared everything explicitly above

  float = {
    padding = 4,
    max_width = 0.6,
    max_height = 0.7,
  },
})

-- ── Top-level entry point ─────────────────────────────────────────────────────
-- TIP: mirrors your `SUPER, E, exec, nemo` Hyprland bind — same mnemonic (E),
-- but stays inside nvim. Float keeps it lightweight for quick rename/move;
-- use <leader>E for a full-buffer tree when browsing a big directory.
vim.keymap.set('n', '<leader>e', function()
  oil.open_float()
end, { desc = 'Oil: file explorer (float, cwd)' })

vim.keymap.set('n', '<leader>E', function()
  oil.open()
end, { desc = 'Oil: file explorer (buffer, cwd)' })
