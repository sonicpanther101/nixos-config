-- ── plugins/treesitter.lua ───────────────────────────────────────────────────
-- Tree-sitter is a PARSER. It builds a concrete syntax tree of your code,
-- which enables:
--   1. Syntax highlighting that actually understands structure (not just regex)
--   2. Indentation that understands the language grammar
--   3. Text objects: `vif` = select inside a function, `]f` = jump to next function
--   4. Incremental selection: <C-space> to expand selection along the tree
--
-- GLSL note: tree-sitter-glsl understands vertex/fragment/compute shader syntax.
-- For it to activate on .vert/.frag/.comp files, those filetypes are registered
-- below in the filetype detection block.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Register shader file extensions ──────────────────────────────────────────
-- Neovim doesn't know about these by default — tell it they're GLSL
vim.filetype.add({
  extension = {
    vert = 'glsl',
    frag = 'glsl',
    geom = 'glsl',
    comp = 'glsl',  -- compute shaders
    tese = 'glsl',  -- tessellation evaluation
    tesc = 'glsl',  -- tessellation control
    glsl = 'glsl',
  },
})

require('nvim-treesitter.configs').setup({
  -- ── Highlighting ─────────────────────────────────────────────────────────
  -- TIP: this replaces vim's regex-based syntax. Colours are more accurate
  -- and update as you type rather than re-scanning the whole buffer.
  highlight = {
    enable                            = true,
    additional_vim_regex_highlighting = false,  -- don't run both (slower + conflicts)
  },

  -- ── Indentation ──────────────────────────────────────────────────────────
  -- TIP: makes `=` (re-indent operator) understand the language grammar.
  -- `gg=G` re-indents the whole file correctly.
  indent = {
    enable = true,
  },

  -- ── Incremental selection ────────────────────────────────────────────────
  -- TIP: <C-space> in normal mode starts a selection on the current node.
  -- Keep pressing to expand to parent node, <BS> to shrink back.
  -- Extremely useful for selecting function bodies, if-blocks, etc.
  incremental_selection = {
    enable  = true,
    keymaps = {
      init_selection    = '<C-space>',  -- start selection
      node_incremental  = '<C-space>',  -- expand to parent
      node_decremental  = '<BS>',       -- shrink to child
      scope_incremental = '<C-s>',      -- expand to enclosing scope
    },
  },

  -- ── Text objects (via nvim-treesitter-textobjects) ────────────────────────
  -- TIP: these give you grammar-aware motions:
  --   `vaf`  = select around a function (including signature)
  --   `vif`  = select inside a function (body only)
  --   `]f`   = jump to next function
  --   `[c`   = jump to previous class
  --   `]a`   = jump to next parameter
  textobjects = {
    select = {
      enable    = true,
      lookahead = true,  -- jump forward to the next match if not on one
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
      enable              = true,
      set_jumps           = true,  -- add to jump list so <C-o>/<C-i> works
      goto_next_start     = {
        [']f'] = { query = '@function.outer', desc = 'Next function start' },
        [']c'] = { query = '@class.outer',    desc = 'Next class start'    },
        [']a'] = { query = '@parameter.inner',desc = 'Next argument'       },
      },
      goto_next_end       = {
        [']F'] = { query = '@function.outer', desc = 'Next function end' },
      },
      goto_previous_start = {
        ['[f'] = { query = '@function.outer', desc = 'Prev function start' },
        ['[c'] = { query = '@class.outer',    desc = 'Prev class start'    },
        ['[a'] = { query = '@parameter.inner',desc = 'Prev argument'       },
      },
      goto_previous_end   = {
        ['[F'] = { query = '@function.outer', desc = 'Prev function end' },
      },
    },
    swap = {
      enable   = true,
      swap_next     = { ['<leader>xp'] = '@parameter.inner' },
      swap_previous = { ['<leader>xP'] = '@parameter.inner' },
    },
  },
})
