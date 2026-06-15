-- ── plugins/completion.lua ───────────────────────────────────────────────────
-- nvim-cmp is the completion engine. Sources feed it candidates:
--   nvim-lsp     → language server completions (functions, types, fields)
--   luasnip      → snippet expansions
--   buffer       → words already in open buffers
--   path         → filesystem paths (useful for #include, import, etc.)
--
-- TIP: this is where completions come from. Supermaven (next file) adds
-- an AI source on top. Together they cover most of what Copilot does in VSCode.
-- ─────────────────────────────────────────────────────────────────────────────

local cmp     = require('cmp')
local luasnip = require('luasnip')

-- Load VSCode-style snippets from friendly-snippets
require('luasnip.loaders.from_vscode').lazy_load()

luasnip.config.setup({
  history            = true,
  update_events      = 'TextChanged,TextChangedI',
  enable_autosnippets = false,
})

cmp.setup({
  completion = {
    autocomplete = false,
  },
  -- ── Snippet engine ─────────────────────────────────────────────────────
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },

  -- ── Keymaps ────────────────────────────────────────────────────────────
  mapping = cmp.mapping.preset.insert({
    -- <C-j>/<C-k> to move through items (matches telescope pattern)
    ['<C-j>']     = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
    ['<C-k>']     = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),

    -- Scroll documentation popup
    ['<C-b>']     = cmp.mapping.scroll_docs(-4),
    ['<C-f>']     = cmp.mapping.scroll_docs(4),

    -- Trigger completion manually (in case it doesn't auto-appear)
    ['<C-Space>'] = cmp.mapping.complete(),

    -- Cancel completion
    ['<C-e>']     = cmp.mapping.abort(),

    -- Confirm — <CR> only confirms if explicitly selected, otherwise just inserts newline
    -- TIP: this is intentional — it stops Enter accidentally completing a snippet
    -- when you just want a new line. Use <Tab> to confirm instead.
    ['<CR>']      = cmp.mapping.confirm({ select = false }),

    -- <Tab> to confirm or jump through snippet placeholders
    -- TIP: after a snippet expands, Tab moves between placeholders (like VSCode)
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.confirm({ select = true })
      elseif luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),

    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),

  -- ── Sources (priority order) ────────────────────────────────────────────
  sources = cmp.config.sources({
    { name = 'cmp_ai', priority = 1100 },  -- AI completions first
    { name = 'nvim_lsp',   priority = 1000 },  -- then LSP
    { name = 'luasnip',    priority  = 750  },  -- then snippets
    { name = 'path',       priority  = 500  },  -- then file paths
  }, {
    { name = 'buffer',     priority = 250,   -- words in open buffers (lower priority)
      option = { get_bufnrs = function()
        -- Only index visible buffers (not the whole workspace)
        local bufs = {}
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          bufs[vim.api.nvim_win_get_buf(win)] = true
        end
        return vim.tbl_keys(bufs)
      end }
    },
  }),

  -- ── Appearance ─────────────────────────────────────────────────────────
  formatting = {
    format = function(entry, vim_item)
      -- Show source name in the menu column
      local source_names = {
        cmp_ai = '[AI]',
        nvim_lsp   = '[LSP]',
        luasnip    = '[Snip]',
        buffer     = '[Buf]',
        path       = '[Path]',
      }
      vim_item.menu = source_names[entry.source.name] or ''
      return vim_item
    end,
  },

  -- Don't show completion in comment lines
  enabled = function()
    local context = require('cmp.config.context')
    if vim.api.nvim_get_mode().mode == 'c' then return true end
    return not context.in_treesitter_capture('comment')
       and not context.in_syntax_group('Comment')
  end,

  window = {
    completion    = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },

  experimental = {
    ghost_text = false,  -- disable ghost text here; Supermaven has its own
  },
})

-- ── Completion for command mode (/search and :commands) ──────────────────────
cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = { { name = 'buffer' } },
})

cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources(
    { { name = 'path' } },
    { { name = 'cmdline', option = { ignore_cmds = { 'Man', '!' } } } }
  ),
})
