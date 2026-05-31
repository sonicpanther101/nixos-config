-- ── plugins/lsp.lua ──────────────────────────────────────────────────────────
-- nvim 0.11 + nvim-lspconfig v2 API.
-- The old `require('lspconfig').server.setup({})` is now a hard error.
-- New pattern:
--   1. vim.lsp.config('*', { capabilities = ... })   ← global defaults
--   2. vim.lsp.config('server', { settings = ... })  ← per-server overrides
--   3. vim.lsp.enable({ 'server1', 'server2', ... }) ← activate them
--   4. LspAttach autocmd                             ← keymaps per buffer
--
-- nvim-lspconfig (on rtp) registers default cmd/filetypes/root_markers for
-- every known server automatically. We only need to override what differs.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Global capabilities ───────────────────────────────────────────────────────
-- Tell every server what nvim-cmp supports. Must happen before vim.lsp.enable.
vim.lsp.config('*', {
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
})

-- ── C / C++ — clangd ─────────────────────────────────────────────────────────
-- TIP: generate compile_commands.json with:
--   cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -B build && ln -s build/compile_commands.json .
-- Without it clangd works but won't know your include paths or flags.
vim.lsp.config('clangd', {
  cmd = {
    'clangd',
    '--background-index',
    '--clang-tidy',
    '--header-insertion=iwyu',
    '--completion-style=detailed',
    '--function-arg-placeholders',
    '--offset-encoding=utf-16',   -- silences nvim-cmp warning
  },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
})

-- ── Python — pyright ─────────────────────────────────────────────────────────
vim.lsp.config('pyright', {
  settings = {
    python = {
      analysis = {
        typeCheckingMode      = 'basic',
        autoImportCompletions = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
})

-- ── GLSL — glsl_analyzer ─────────────────────────────────────────────────────
-- Handles .vert .frag .geom .comp files (registered as 'glsl' filetype in treesitter.lua)
vim.lsp.config('glsl_analyzer', {
  filetypes = { 'glsl', 'vert', 'frag', 'geom', 'comp', 'tese', 'tesc' },
})

-- ── Nix — nixd ───────────────────────────────────────────────────────────────
vim.lsp.config('nixd', {
  settings = {
    nixd = {
      nixpkgs = {
        expr = 'import (builtins.getFlake "' .. vim.fn.expand('~/nixos-config') .. '").inputs.nixpkgs-unstable {}',
      },
      options = {
        nixos = {
          expr = '(builtins.getFlake "' .. vim.fn.expand('~/nixos-config') .. '").nixosConfigurations.desktop.options',
        },
      },
    },
  },
})

-- ── Lua — lua_ls ─────────────────────────────────────────────────────────────
-- Teaches it about vim.* globals so editing your neovim config has full completions.
vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime    = { version = 'LuaJIT' },
      workspace  = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file('', true),
      },
      diagnostics = { globals = { 'vim' } },
      telemetry   = { enable = false },
    },
  },
})

-- ── Enable all servers ────────────────────────────────────────────────────────
-- nvim-lspconfig provides the default cmd/filetypes/root_markers for each.
vim.lsp.enable({
  'clangd',
  'pyright',
  'glsl_analyzer',
  'cmake',
  'nixd',
  'hyprls',
  'lua_ls',
})

-- ── Keymaps (set per-buffer when an LSP attaches) ─────────────────────────────
-- TIP: these only activate in buffers where an LSP is running.
-- Compare to VSCodium: gd=F12, K=hover, <leader>rn=F2, <leader>ca=Ctrl+.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('my-lsp-keymaps', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = event.buf, silent = true, desc = 'LSP: ' .. desc })
    end

    local tb = require('telescope.builtin')
    map('gd',         tb.lsp_definitions,              'Go to definition')
    map('gD',         vim.lsp.buf.declaration,         'Go to declaration')
    map('gr',         tb.lsp_references,               'Find references')
    map('gI',         tb.lsp_implementations,          'Go to implementation')
    map('gt',         tb.lsp_type_definitions,         'Go to type definition')
    map('K',          vim.lsp.buf.hover,               'Hover docs')
    map('<C-k>',      vim.lsp.buf.signature_help,      'Signature help')
    map('<leader>rn', vim.lsp.buf.rename,              'Rename symbol')
    map('<leader>ca', vim.lsp.buf.code_action,         'Code action')
    map('<leader>cf', function()
      vim.lsp.buf.format({ async = true })
    end, 'Format file')

    -- Toggle inlay hints (shows parameter names and inferred types inline)
    if vim.lsp.inlay_hint then
      map('<leader>ci', function()
        vim.lsp.inlay_hint.enable(
          not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }),
          { bufnr = event.buf }
        )
      end, 'Toggle inlay hints')
    end
  end,
})

-- ── Diagnostic display ────────────────────────────────────────────────────────
vim.diagnostic.config({
  virtual_text     = { prefix = '●' },
  signs            = true,
  underline        = true,
  update_in_insert = false,
  severity_sort    = true,
  float            = { border = 'rounded', source = true },
})

local signs = { Error = '', Warn = '', Hint = '󰠠', Info = '' }
for type, icon in pairs(signs) do
  local hl = 'DiagnosticSign' .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
