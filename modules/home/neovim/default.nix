{ pkgs-stable, pkgs-unstable, ... }:
let
  # Pull vimPlugins once so references are unambiguous
  vp = pkgs-unstable.vimPlugins;
in {

  programs.neovim = {
    enable        = true;
    package       = pkgs-unstable.neovim-unwrapped;
    defaultEditor = true;
    viAlias       = true;
    vimAlias      = true;

    extraPackages = with pkgs-unstable; [
      clang-tools
      pyright
      glsl_analyzer
      cmake-language-server
      hyprls
      nixd
      lua-language-server
      ripgrep
      fd
      black
    ];

    plugins = [
      # ── Colourscheme ───────────────────────────────────────────────────────
      vp.catppuccin-nvim

      # ── Fuzzy finding ──────────────────────────────────────────────────────
      vp.telescope-nvim
      vp.telescope-fzf-native-nvim
      vp.plenary-nvim

      # ── File bookmarks ─────────────────────────────────────────────────────
      vp.harpoon2

      # ── Treesitter — must be specified this way for home-manager to correctly
      # add it to the runtimepath. withAllGrammars bundles every parser as a
      # single derivation; Nix handles it, nvim never tries to download grammars.
      vp.nvim-treesitter.withAllGrammars
      vp.nvim-treesitter-textobjects

      # ── LSP ────────────────────────────────────────────────────────────────
      vp.nvim-lspconfig

      # ── Completion ─────────────────────────────────────────────────────────
      vp.nvim-cmp
      vp.cmp-nvim-lsp
      vp.cmp-buffer
      vp.cmp-path
      vp.cmp-cmdline
      vp.luasnip
      vp.cmp_luasnip
      vp.friendly-snippets

      # ── AI completion via ollama ────────────────────────────────────────────
      vp.cmp-ai

      # ── UI ─────────────────────────────────────────────────────────────────
      vp.lualine-nvim
      vp.nvim-web-devicons
      vp.which-key-nvim
      vp.gitsigns-nvim

      # ── Editing helpers ────────────────────────────────────────────────────
      vp.nvim-surround
      vp.comment-nvim
      vp.nvim-autopairs
      vp.vim-visual-multi
      vp.indent-blankline-nvim
      vp.todo-comments-nvim
      vp.trouble-nvim
      vp.undotree

      # ── Fun ────────────────────────────────────────────────────────────────
      vp.vim-be-good
    ];

    extraLuaConfig = ''
      require('options')
      require('keymaps')
      require('plugins.ui')
      require('plugins.telescope')
      require('plugins.harpoon')
      require('plugins.treesitter')
      require('plugins.lsp')
      require('plugins.completion')
      require('plugins.ollama-completion')
      require('plugins.editing')
    '';
  };

  xdg.configFile = {
    "nvim/lua/options.lua".source                    = ./options.lua;
    "nvim/lua/keymaps.lua".source                    = ./keymaps.lua;
    "nvim/lua/plugins/ui.lua".source                 = ./plugins/ui.lua;
    "nvim/lua/plugins/telescope.lua".source          = ./plugins/telescope.lua;
    "nvim/lua/plugins/harpoon.lua".source            = ./plugins/harpoon.lua;
    "nvim/lua/plugins/treesitter.lua".source         = ./plugins/treesitter.lua;
    "nvim/lua/plugins/lsp.lua".source                = ./plugins/lsp.lua;
    "nvim/lua/plugins/completion.lua".source         = ./plugins/completion.lua;
    "nvim/lua/plugins/ollama-completion.lua".source  = ./plugins/ollama-completion.lua;
    "nvim/lua/plugins/editing.lua".source            = ./plugins/editing.lua;
  };
}
