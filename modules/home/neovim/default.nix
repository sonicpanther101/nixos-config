{ pkgs-stable, pkgs-unstable, ... }:
let
  vp = pkgs-unstable.vimPlugins;

  # Bind this so we can interpolate the store path directly into initLua.
  # This bypasses home-manager's rtp mechanism entirely — nvim will always
  # find the module regardless of how plugins are added to rtp.
  treesitter = vp.nvim-treesitter.withAllGrammars;
in {

  programs.neovim = {
    enable        = true;
    package       = pkgs-unstable.neovim-unwrapped;
    defaultEditor = true;
    viAlias       = true;
    vimAlias      = true;

    withRuby    = false;
    withPython3 = true;

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
      prettier
      black
    ];

    plugins = [
      vp.catppuccin-nvim
      vp.telescope-nvim
      vp.telescope-fzf-native-nvim
      vp.plenary-nvim
      vp.harpoon2

      # Still list it here so home-manager knows about it
      treesitter
      vp.nvim-treesitter-textobjects

      vp.nvim-lspconfig
      vp.nvim-cmp
      vp.cmp-nvim-lsp
      vp.cmp-buffer
      vp.cmp-path
      vp.cmp-cmdline
      vp.luasnip
      vp.cmp_luasnip
      vp.friendly-snippets
      vp.cmp-ai

      vp.lualine-nvim
      vp.nvim-web-devicons
      vp.which-key-nvim
      vp.gitsigns-nvim

      vp.nvim-surround
      vp.comment-nvim
      vp.nvim-autopairs
      vp.vim-visual-multi
      vp.indent-blankline-nvim
      vp.todo-comments-nvim
      vp.trouble-nvim
      vp.undotree
      vp.vim-be-good
    ];

    initLua = ''
      -- Force treesitter onto rtp using its exact nix store path.
      -- This is necessary because home-manager's rtp injection for withAllGrammars
      -- is unreliable with neovim-unwrapped. The path is stamped at build time.
      vim.opt.rtp:prepend("${treesitter}")

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
    "nvim/lua/options.lua".source                   = ./options.lua;
    "nvim/lua/keymaps.lua".source                   = ./keymaps.lua;
    "nvim/lua/plugins/ui.lua".source                = ./plugins/ui.lua;
    "nvim/lua/plugins/telescope.lua".source         = ./plugins/telescope.lua;
    "nvim/lua/plugins/harpoon.lua".source           = ./plugins/harpoon.lua;
    "nvim/lua/plugins/treesitter.lua".source        = ./plugins/treesitter.lua;
    "nvim/lua/plugins/lsp.lua".source               = ./plugins/lsp.lua;
    "nvim/lua/plugins/completion.lua".source        = ./plugins/completion.lua;
    "nvim/lua/plugins/ollama-completion.lua".source = ./plugins/ollama-completion.lua;
    "nvim/lua/plugins/editing.lua".source           = ./plugins/editing.lua;
  };
}
