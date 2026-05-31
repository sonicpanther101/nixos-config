-- ── plugins/ui.lua ───────────────────────────────────────────────────────────
-- catppuccin MUST be set up and applied before lualine tries to load
-- its catppuccin theme — order matters here.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Catppuccin ───────────────────────────────────────────────────────────────
local ok_ctp, catppuccin = pcall(require, 'catppuccin')
if ok_ctp then
  catppuccin.setup({
    flavour    = 'mocha',
    background = { dark = 'mocha', light = 'latte' },
    integrations = {
      cmp        = true,
      gitsigns   = true,
      telescope  = { enabled = true },
      treesitter = true,
      which_key  = true,
      harpoon    = true,
      indent_blankline = { enabled = true },
      mini       = { enabled = true },
    },
  })
  vim.cmd.colorscheme('catppuccin')
else
  -- Fallback so startup doesn't die if catppuccin isn't on rtp yet
  vim.cmd.colorscheme('habamax')
  vim.notify('catppuccin not found: ' .. catppuccin, vim.log.levels.WARN)
end

-- ── Lualine ──────────────────────────────────────────────────────────────────
-- Use 'auto' so it picks up whatever colorscheme is active rather than
-- requiring catppuccin's lualine theme file to be on a specific path.
local ok_ll, lualine = pcall(require, 'lualine')
if ok_ll then
  lualine.setup({
    options = {
      theme                = 'auto',
      component_separators = { left = '', right = '' },
      section_separators   = { left = '', right = '' },
      globalstatus         = true,
    },
    sections = {
      lualine_a = { 'mode' },
      lualine_b = { 'branch', 'diff', 'diagnostics' },
      lualine_c = { { 'filename', path = 1 } },
      lualine_x = { 'encoding', 'fileformat', 'filetype' },
      lualine_y = { 'progress' },
      lualine_z = { 'location' },
    },
  })
end

-- ── Which-key ────────────────────────────────────────────────────────────────
local ok_wk, which_key = pcall(require, 'which-key')
if ok_wk then
  which_key.setup({ delay = 300 })
  which_key.add({
    { '<leader>s', group = 'Search (telescope)' },
    { '<leader>b', group = 'Buffer' },
    { '<leader>g', group = 'Git' },
    { '<leader>n', group = 'Neovim config' },
    { '<leader>c', group = 'Code (LSP)' },
    { '<leader>x', group = 'Trouble / diagnostics' },
  })
end

-- ── Gitsigns ─────────────────────────────────────────────────────────────────
local ok_gs, gitsigns = pcall(require, 'gitsigns')
if ok_gs then
  gitsigns.setup({
    signs = {
      add          = { text = '│' },
      change       = { text = '│' },
      delete       = { text = '_' },
      topdelete    = { text = '‾' },
      changedelete = { text = '~' },
      untracked    = { text = '┆' },
    },
    on_attach = function(bufnr)
      local gs  = package.loaded.gitsigns
      local map = function(mode, l, r, opts)
        vim.keymap.set(mode, l, r, vim.tbl_extend('force', { buffer = bufnr, silent = true }, opts or {}))
      end
      map('n', ']c', function() if vim.wo.diff then return ']c' end vim.schedule(gs.next_hunk) return '<Ignore>' end, { expr = true, desc = 'Git: next hunk' })
      map('n', '[c', function() if vim.wo.diff then return '[c' end vim.schedule(gs.prev_hunk) return '<Ignore>' end, { expr = true, desc = 'Git: prev hunk' })
      map('n', '<leader>gs', gs.stage_hunk,   { desc = 'Git: stage hunk'   })
      map('n', '<leader>gr', gs.reset_hunk,   { desc = 'Git: reset hunk'   })
      map('n', '<leader>gb', gs.blame_line,   { desc = 'Git: blame line'   })
      map('n', '<leader>gd', gs.diffthis,     { desc = 'Git: diff file'    })
      map('n', '<leader>gp', gs.preview_hunk, { desc = 'Git: preview hunk' })
    end,
  })
end

-- ── Indent blankline ─────────────────────────────────────────────────────────
local ok_ibl, ibl = pcall(require, 'ibl')
if ok_ibl then
  ibl.setup({
    indent = { char = '│' },
    scope  = { enabled = true },
  })
end

-- ── Todo comments ────────────────────────────────────────────────────────────
local ok_td, todo = pcall(require, 'todo-comments')
if ok_td then
  todo.setup()
  vim.keymap.set('n', '<leader>st', '<cmd>TodoTelescope<CR>', { desc = 'Search: TODOs' })
  vim.keymap.set('n', ']t', function() todo.jump_next() end, { desc = 'Next TODO' })
  vim.keymap.set('n', '[t', function() todo.jump_prev() end, { desc = 'Prev TODO' })
end

-- ── Trouble ───────────────────────────────────────────────────────────────────
local ok_tr, trouble = pcall(require, 'trouble')
if ok_tr then
  trouble.setup({ use_diagnostic_signs = true })
  local map = function(l, r, desc)
    vim.keymap.set('n', l, r, { silent = true, desc = desc })
  end
  map('<leader>xx', '<cmd>Trouble diagnostics toggle<CR>',               'Trouble: workspace diagnostics')
  map('<leader>xb', '<cmd>Trouble diagnostics toggle filter.buf=0<CR>',  'Trouble: buffer diagnostics')
  map('<leader>xs', '<cmd>Trouble symbols toggle<CR>',                   'Trouble: symbols')
  map('<leader>xq', '<cmd>Trouble qflist toggle<CR>',                    'Trouble: quickfix')
end

-- ── Undotree ─────────────────────────────────────────────────────────────────
vim.keymap.set('n', '<leader>u', '<cmd>UndotreeToggle<CR>', { desc = 'Undotree: toggle' })
