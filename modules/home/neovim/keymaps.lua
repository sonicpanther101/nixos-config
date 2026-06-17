-- ── keymaps.lua ──────────────────────────────────────────────────────────────
-- TIP: modes
--   'n' = normal (navigating)     'i' = insert (typing)
--   'v' = visual (selection)      'x' = visual only (not select mode)
--   'c' = command (:)             't' = terminal
--
-- `noremap = true` means the rhs is not itself remapped — always use this
-- unless you deliberately want chaining.
-- `silent = true` means the mapping isn't echoed in the command line.
-- ─────────────────────────────────────────────────────────────────────────────

local map = function(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend('force', { noremap = true, silent = true }, opts or {}))
end

-- ── Leader key ───────────────────────────────────────────────────────────────
-- TIP: <leader> is a prefix key — it does nothing alone but starts sequences.
-- Space is the most popular choice: easy to hit, never conflicts with vim defaults.
vim.g.mapleader      = ' '
vim.g.maplocalleader = ' '

-- ── Better defaults ──────────────────────────────────────────────────────────

-- Don't move cursor on * search, just highlight
map('n', '*', '*N')

-- Keep cursor centred when jumping search results / half-page
-- TIP: <C-d>/<C-u> are half-page down/up — with zz they keep your eye centred
map('n', '<C-d>', '<C-d>zz')
map('n', '<C-u>', '<C-u>zz')
map('n', 'n',     'nzzzv')
map('n', 'N',     'Nzzzv')

-- Clear search highlight with Escape in normal mode
map('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Save with Ctrl+S (familiar from VSCodium)
map({ 'n', 'i' }, '<C-s>', '<cmd>w<CR><Esc>')

-- Close buffer without closing the split
map('n', '<leader>bd', '<cmd>bd<CR>',  { desc = 'Buffer: delete' })
map('n', '<leader>bn', '<cmd>bn<CR>',  { desc = 'Buffer: next' })
map('n', '<leader>bp', '<cmd>bp<CR>',  { desc = 'Buffer: prev' })

-- ── Window navigation ────────────────────────────────────────────────────────
-- TIP: <C-w>v splits vertically, <C-w>s horizontally.
-- These make moving between splits feel like Vim motions.
map('n', '<C-h>', '<C-w>h', { desc = 'Window: left'  })
map('n', '<C-j>', '<C-w>j', { desc = 'Window: down'  })
map('n', '<C-k>', '<C-w>k', { desc = 'Window: up'    })
map('n', '<C-l>', '<C-w>l', { desc = 'Window: right' })

-- ── Indenting in visual mode keeps selection ─────────────────────────────────
-- TIP: normally < or > exits visual mode. This lets you tap repeatedly.
map('v', '<', '<gv')
map('v', '>', '>gv')

-- ── Move selected lines up/down ──────────────────────────────────────────────
map('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
map('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selection up'   })

-- ── Don't yank on paste in visual mode ───────────────────────────────────────
-- TIP: by default pasting over a selection yanks the replaced text.
-- This black-holes it so your yank register isn't clobbered.
map('x', 'p', '"_dP')

-- ── Yank to system clipboard explicitly ──────────────────────────────────────
-- (clipboard=unnamedplus makes y/p use system clipboard anyway,
-- but these are useful if you ever disable that)
map({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'Yank to clipboard' })
map('n',          '<leader>Y', '"+Y', { desc = 'Yank line to clipboard' })

-- ── Delete without yanking ───────────────────────────────────────────────────
-- TIP: d normally yanks what it deletes. <leader>d deletes to /dev/null.
map({ 'n', 'v' }, '<leader>d', '"_d', { desc = 'Delete without yank' })

-- ── Quick-edit config ────────────────────────────────────────────────────────
map('n', '<leader>nn', '<cmd>e ~/nixos-config/modules/home/neovim/lua/<CR>',
  { desc = 'Neovim: open lua config dir' })

-- ── Diagnostic navigation ────────────────────────────────────────────────────
-- TIP: [d and ]d jump between LSP errors/warnings (like the squigglies in VSCode)
map('n', '[d', function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = 'Diagnostic: previous' })

map('n', ']d', function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = 'Diagnostic: next' })
map('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code Action', silent = true })
map('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Diagnostic: show message' })
map('n', '<leader>q', vim.diagnostic.setloclist,  { desc = 'Diagnostic: list all'    })

-- ── Terminal ─────────────────────────────────────────────────────────────────
-- TIP: <C-\><C-n> exits terminal insert mode back to normal mode
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Terminal: exit insert mode' })
map('n', '<leader>t',  '<cmd>split | terminal<CR>i', { desc = 'Terminal: open in split' })
