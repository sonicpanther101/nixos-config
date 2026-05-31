-- ── plugins/ui.lua ───────────────────────────────────────────────────────────

-- ── Catppuccin colourscheme ───────────────────────────────────────────────────
require('catppuccin').setup({
  flavour    = 'mocha',
  background = { dark = 'mocha', light = 'latte' },
  integrations = {
    cmp         = true,
    gitsigns    = true,
    telescope   = { enabled = true },
    treesitter  = true,
    which_key   = true,
    lsp_trouble = true,
    harpoon     = true,
  },
})
vim.cmd.colorscheme('catppuccin')

-- ── Lualine (statusline) ─────────────────────────────────────────────────────
-- TIP: the statusline shows mode, file, git branch, LSP errors, cursor position.
-- Much more information-dense than the default vim one.
require('lualine').setup({
  options = {
    theme           = 'catppuccin',
    component_separators = { left = '', right = '' },
    section_separators  = { left = '', right = '' },
    globalstatus    = true,  -- single statusline at the bottom of the screen
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch', 'diff', 'diagnostics' },
    lualine_c = { { 'filename', path = 1 } },  -- path=1 shows relative path
    lualine_x = { 'encoding', 'fileformat', 'filetype' },
    lualine_y = { 'progress' },
    lualine_z = { 'location' },
  },
})

-- ── Which-key ────────────────────────────────────────────────────────────────
-- TIP: press <leader> and wait — a popup appears showing all available
-- keymaps starting with <leader>. Great while you're learning.
require('which-key').setup({
  delay = 300,  -- ms before popup appears
})

-- Register group labels so the popup is organised
require('which-key').add({
  { '<leader>s', group = 'Search (telescope)' },
  { '<leader>b', group = 'Buffer' },
  { '<leader>g', group = 'Git' },
  { '<leader>n', group = 'Neovim config' },
  { '<leader>c', group = 'Code (LSP)' },
})

-- ── Gitsigns ─────────────────────────────────────────────────────────────────
-- TIP: shows git changes in the sign column (+ added, ~ changed, _ deleted).
-- Also lets you stage individual hunks without leaving neovim.
require('gitsigns').setup({
  signs = {
    add          = { text = '│' },
    change       = { text = '│' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns
    local map = function(mode, l, r, opts)
      vim.keymap.set(mode, l, r, vim.tbl_extend('force', { buffer = bufnr, silent = true }, opts or {}))
    end

    -- TIP: ]c / [c jump between changed hunks (like clicking diff arrows in VSCode)
    map('n', ']c', function() if vim.wo.diff then return ']c' end vim.schedule(gs.next_hunk) return '<Ignore>' end,
      { expr = true, desc = 'Git: next hunk' })
    map('n', '[c', function() if vim.wo.diff then return '[c' end vim.schedule(gs.prev_hunk) return '<Ignore>' end,
      { expr = true, desc = 'Git: prev hunk' })

    map('n', '<leader>gs', gs.stage_hunk,   { desc = 'Git: stage hunk'   })
    map('n', '<leader>gr', gs.reset_hunk,   { desc = 'Git: reset hunk'   })
    map('n', '<leader>gb', gs.blame_line,   { desc = 'Git: blame line'   })
    map('n', '<leader>gd', gs.diffthis,     { desc = 'Git: diff file'    })
    map('n', '<leader>gp', gs.preview_hunk, { desc = 'Git: preview hunk' })
  end,
})
