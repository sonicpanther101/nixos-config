-- ── plugins/lsp.lua ──────────────────────────────────────────────────────────
-- LSP = Language Server Protocol. The exact same system VSCode uses for
-- intellisense. Each language has a server process that Neovim talks to:
--
--   clangd         → C, C++ (and can handle GLSL via compile_commands.json)
--   pyright        → Python (type-checked, understands imports)
--   glsl_analyzer  → GLSL shaders
--   cmake-ls       → CMakeLists.txt
--   nixd           → Nix (already in your config)
--   hyprls         → Hyprland config files
--
-- nvim-lspconfig knows the command to run for each server. The servers
-- themselves are installed as Nix packages in default.nix extraPackages.
--
-- The on_attach function runs when an LSP connects to a buffer — that's
-- where LSP-specific keymaps are set (so they only work in LSP buffers).
-- ─────────────────────────────────────────────────────────────────────────────

local lspconfig = require('lspconfig')

-- ── Capabilities ─────────────────────────────────────────────────────────────
-- Tell each server what nvim-cmp can handle (richer completion data).
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- ── on_attach: keymaps active in any LSP buffer ──────────────────────────────
-- TIP: these are the core "IDE" actions. Compare to VSCodium:
--   gd  = Go to Definition (F12 in VSCode)
--   K   = Hover docs        (hover in VSCode)
--   gr  = Find references   (Shift+F12)
--   <leader>rn = Rename     (F2)
--   <leader>ca = Code action (Ctrl+. in VSCode — lightbulb)
local on_attach = function(_, bufnr)
  local map = function(keys, func, desc)
    vim.keymap.set('n', keys, func, { buffer = bufnr, silent = true, desc = 'LSP: ' .. desc })
  end

  local telescope = require('telescope.builtin')

  map('gd',         telescope.lsp_definitions,      'Go to definition')
  map('gD',         vim.lsp.buf.declaration,         'Go to declaration')
  map('gr',         telescope.lsp_references,        'Find references')
  map('gI',         telescope.lsp_implementations,   'Go to implementation')
  map('gt',         telescope.lsp_type_definitions,  'Go to type definition')
  map('K',          vim.lsp.buf.hover,               'Hover documentation')
  map('<C-k>',      vim.lsp.buf.signature_help,      'Signature help')  -- in insert mode too
  map('<leader>rn', vim.lsp.buf.rename,              'Rename symbol')
  map('<leader>ca', vim.lsp.buf.code_action,         'Code action')
  map('<leader>cf', vim.lsp.buf.format,              'Format file')

  -- Inlay hints (type annotations shown inline, like VSCode's ghost text)
  -- TIP: shows parameter names and return types inline without cluttering the code
  if vim.lsp.inlay_hint then
    map('<leader>ci', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end, 'Toggle inlay hints')
  end
end

-- ── Diagnostic display ───────────────────────────────────────────────────────
-- TIP: by default errors show as virtual text on the right. This makes them
-- slightly less aggressive — hover over a squiggly with K to see the message.
vim.diagnostic.config({
  virtual_text = {
    prefix = '●',
  },
  signs            = true,
  underline        = true,
  update_in_insert = false,   -- don't show errors while mid-sentence in insert mode
  severity_sort    = true,
  float = {
    border = 'rounded',
    source = 'always',        -- always show which server reported the error
  },
})

-- Custom diagnostic sign icons (matches the gutter symbols)
local signs = { Error = '', Warn = '', Hint = '󰠠', Info = '' }
for type, icon in pairs(signs) do
  local hl = 'DiagnosticSign' .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- ── C / C++ — clangd ─────────────────────────────────────────────────────────
-- TIP: clangd reads compile_commands.json from your build directory.
-- For CMake: `cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -B build` then
-- `ln -s build/compile_commands.json .` in the project root.
-- Without it, clangd still works but won't know your include paths.
--
-- The --offset-encoding flag silences a warning from nvim-cmp.
lspconfig.clangd.setup({
  capabilities = vim.tbl_deep_extend('force', capabilities, {
    offsetEncoding = { 'utf-16' },
  }),
  on_attach = on_attach,
  cmd = {
    'clangd',
    '--background-index',      -- index project in background on first open
    '--clang-tidy',            -- run clang-tidy checks (like a linter on top of the LSP)
    '--header-insertion=iwyu', -- suggest headers to include (IWYU = include what you use)
    '--completion-style=detailed',
    '--function-arg-placeholders', -- show parameter placeholders in completions
  },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
})

-- ── Python — pyright ─────────────────────────────────────────────────────────
-- TIP: pyright is Microsoft's type checker — same one used in Pylance (VSCode).
-- It understands type annotations, imports, and virtual environments.
-- Point `pythonPath` to your venv if you use one:
--   :lua vim.lsp.buf.workspace_configuration()  to inspect active config
lspconfig.pyright.setup({
  capabilities = capabilities,
  on_attach    = on_attach,
  settings = {
    python = {
      analysis = {
        typeCheckingMode     = 'basic',   -- 'off' | 'basic' | 'strict'
        autoImportCompletions = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
})

-- ── GLSL — glsl_analyzer ─────────────────────────────────────────────────────
-- TIP: glsl_analyzer handles vertex, fragment, geometry, and compute shaders.
-- It validates uniform names, built-in variables (gl_Position, gl_FragColor),
-- and knows the GLSL version spec. Set the version in a comment if needed:
--   // #version 460 core
--
-- Filetypes: `glsl` is set for all shader extensions in treesitter.lua
lspconfig.glsl_analyzer.setup({
  capabilities = capabilities,
  on_attach    = on_attach,
  filetypes    = { 'glsl', 'vert', 'frag', 'geom', 'comp', 'tese', 'tesc' },
})

-- ── CMake — cmake-language-server ────────────────────────────────────────────
-- TIP: gives completions for CMake commands (target_link_libraries, etc.),
-- shows docs on hover, and validates CMakeLists.txt syntax.
lspconfig.cmake.setup({
  capabilities = capabilities,
  on_attach    = on_attach,
})

-- ── Nix — nixd ───────────────────────────────────────────────────────────────
-- TIP: nixd understands flake inputs, module options, and builtins.
-- Set the nixpkgs input so it can resolve `pkgs.*` completions in your flake.
lspconfig.nixd.setup({
  capabilities = capabilities,
  on_attach    = on_attach,
  settings = {
    nixd = {
      nixpkgs = {
        -- Points nixd at your flake's nixpkgs so it can resolve package names
        expr = 'import (builtins.getFlake "' .. vim.fn.expand('~/nixos-config') .. '").inputs.nixpkgs-unstable {}',
      },
      formatting = {
        command = { 'nixfmt' },  -- install nixfmt if you want auto-format
      },
      options = {
        nixos = {
          expr = '(builtins.getFlake "' .. vim.fn.expand('~/nixos-config') .. '").nixosConfigurations.desktop.options',
        },
        home_manager = {
          expr = '(builtins.getFlake "' .. vim.fn.expand('~/nixos-config') .. '").nixosConfigurations.desktop.options.home-manager',
        },
      },
    },
  },
})

-- ── Hyprland — hyprls ────────────────────────────────────────────────────────
lspconfig.hyprls.setup({
  capabilities = capabilities,
  on_attach    = on_attach,
})

-- ── Lua — lua_ls ─────────────────────────────────────────────────────────────
-- For editing init.lua and plugin configs. Understands vim.* globals.
lspconfig.lua_ls.setup({
  capabilities = capabilities,
  on_attach    = on_attach,
  settings = {
    Lua = {
      runtime  = { version = 'LuaJIT' },    -- Neovim uses LuaJIT
      workspace = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file('', true),  -- teach it about vim.*
      },
      diagnostics = { globals = { 'vim' } }, -- don't warn about `vim` being undefined
      telemetry   = { enable = false },
    },
  },
})
