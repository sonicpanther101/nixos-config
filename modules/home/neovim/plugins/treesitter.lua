-- ── plugins/treesitter.lua ───────────────────────────────────────────────────

-- Register shader file extensions
vim.filetype.add({
  extension = {
    vert = 'glsl', frag = 'glsl', geom = 'glsl',
    comp = 'glsl', tese = 'glsl', tesc = 'glsl', glsl = 'glsl',
  },
})

local ok, configs = pcall(require, 'nvim-treesitter.configs')
if not ok then
  vim.notify('nvim-treesitter not found — skipping treesitter setup', vim.log.levels.WARN)
  return
end

configs.setup({
  -- Nix bundles grammars via withAllGrammars — never download at runtime
  ensure_installed = {},
  auto_install     = false,

  highlight = {
    enable                            = true,
    additional_vim_regex_highlighting = false,
  },

  indent = { enable = true },

  incremental_selection = {
    enable  = true,
    keymaps = {
      init_selection   = '<C-space>',
      node_incremental = '<C-space>',
      node_decremental = '<BS>',
      scope_incremental = '<C-s>',
    },
  },

  textobjects = {
    select = {
      enable    = true,
      lookahead = true,
      keymaps   = {
        ['af'] = { query = '@function.outer', desc = 'Around function'  },
        ['if'] = { query = '@function.inner', desc = 'Inside function'  },
        ['ac'] = { query = '@class.outer',    desc = 'Around class'     },
        ['ic'] = { query = '@class.inner',    desc = 'Inside class'     },
        ['aa'] = { query = '@parameter.outer',desc = 'Around argument'  },
        ['ia'] = { query = '@parameter.inner',desc = 'Inside argument'  },
        ['ab'] = { query = '@block.outer',    desc = 'Around block'     },
        ['ib'] = { query = '@block.inner',    desc = 'Inside block'     },
      },
    },
    move = {
      enable          = true,
      set_jumps       = true,
      goto_next_start = {
        [']f'] = { query = '@function.outer', desc = 'Next function start' },
        [']c'] = { query = '@class.outer',    desc = 'Next class start'    },
        [']a'] = { query = '@parameter.inner',desc = 'Next argument'       },
      },
      goto_next_end = {
        [']F'] = { query = '@function.outer', desc = 'Next function end' },
      },
      goto_previous_start = {
        ['[f'] = { query = '@function.outer', desc = 'Prev function start' },
        ['[c'] = { query = '@class.outer',    desc = 'Prev class start'    },
        ['[a'] = { query = '@parameter.inner',desc = 'Prev argument'       },
      },
      goto_previous_end = {
        ['[F'] = { query = '@function.outer', desc = 'Prev function end' },
      },
    },
    swap = {
      enable        = true,
      swap_next     = { ['<leader>xp'] = '@parameter.inner' },
      swap_previous = { ['<leader>xP'] = '@parameter.inner' },
    },
  },
})
