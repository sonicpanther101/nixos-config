-- ── plugins/telescope.lua ────────────────────────────────────────────────────
-- Telescope is a fuzzy finder. Think VSCode's Ctrl+P (file search) and
-- Ctrl+Shift+F (grep in project) — except it's used for *everything*:
-- files, buffers, LSP symbols, git commits, help tags, etc.
--
-- The fzf-native extension compiles a C sorter that makes large repos fast.
-- ─────────────────────────────────────────────────────────────────────────────

local telescope = require('telescope')
local actions   = require('telescope.actions')

telescope.setup({
  defaults = {
    -- TIP: the prompt is at the top, results below, preview to the right.
    -- <C-j>/<C-k> moves through results, <CR> selects, <C-q> sends to quickfix.
    mappings = {
      i = {  -- insert mode (while typing the query)
        ['<C-k>']   = actions.move_selection_previous,
        ['<C-j>']   = actions.move_selection_next,
        ['<C-q>']   = actions.send_to_qflist + actions.open_qflist,
        ['<Esc>']   = actions.close,
      },
    },
    file_ignore_patterns = {
      'node_modules', '%.git/', '%.cache', 'result/', '%.direnv/',
    },
    -- Layout
    sorting_strategy = 'ascending',
    layout_config = {
      prompt_position = 'top',
      width  = 0.87,
      height = 0.80,
    },
  },
  pickers = {
    find_files = {
      hidden = true,  -- include dotfiles
    },
  },
})

-- Load the compiled fzf sorter (needs telescope-fzf-native installed)
telescope.load_extension('fzf')

-- ── Keymaps ──────────────────────────────────────────────────────────────────
local builtin = require('telescope.builtin')
local map     = function(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { silent = true, desc = desc })
end

-- TIP: think of <leader>s as "search" — every search lives here.

map('<leader>sf', builtin.find_files,                 'Search: files')
map('<leader>sg', builtin.live_grep,                  'Search: grep in project')
map('<leader>sw', builtin.grep_string,                'Search: word under cursor')
map('<leader>sb', builtin.buffers,                    'Search: open buffers')
map('<leader>sh', builtin.help_tags,                  'Search: help')
map('<leader>sk', builtin.keymaps,                    'Search: keymaps')
map('<leader>sd', builtin.diagnostics,                'Search: diagnostics')
map('<leader>sr', builtin.resume,                     'Search: resume last')
map('<leader>s.', builtin.oldfiles,                   'Search: recent files')
map('<leader>ss', builtin.lsp_document_symbols,       'Search: document symbols')
map('<leader>sS', builtin.lsp_dynamic_workspace_symbols, 'Search: workspace symbols')

-- TIP: <C-p> is the VSCode muscle-memory keybind for file search
vim.keymap.set('n', '<C-p>', builtin.find_files, { silent = true, desc = 'Search: files' })

-- Search neovim config quickly
vim.keymap.set('n', '<leader>sn', function()
  builtin.find_files({ cwd = vim.fn.stdpath('config') })
end, { desc = 'Search: neovim config files' })
