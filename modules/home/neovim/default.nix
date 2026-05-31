{ pkgs-stable, pkgs-unstable, ... }: {

  # ─── Neovim ──────────────────────────────────────────────────────────────────
  # Nix manages plugins (no plugin manager like lazy.nvim needed for installation)
  # but we still write all config in Lua — best of both worlds.
  # LSP servers are installed as normal Nix packages so they're always on PATH.
  # ─────────────────────────────────────────────────────────────────────────────

  programs.neovim = {
    enable    = true;
    package   = pkgs-unstable.neovim-unwrapped;
    defaultEditor = true;  # sets $EDITOR=nvim
    viAlias   = true;      # `vi` opens nvim
    vimAlias  = true;      # `vim` opens nvim

    withRuby = false;
    withPython3 = true;

    # ── LSP servers & tools Neovim calls out to ───────────────────────────────
    # These land on PATH inside Neovim so nvim-lspconfig can find them.
    extraPackages = with pkgs-unstable; [
      # C / C++ ── clangd ships inside clang-tools
      clang-tools

      # Python
      pyright

      # GLSL (vertex/fragment/compute shaders)
      glsl_analyzer

      # CMake
      cmake-language-server

      # Hyprland config files
      hyprls

      # Nix
      nixd

      # Telescope needs ripgrep (live_grep) and fd (find_files)
      ripgrep
      fd

      # Lua (for editing init.lua / plugin configs)
      lua-language-server

      # Formatter helpers (optional but useful)
      prettier   # JS/JSON/YAML/Markdown
      black                   # Python
    ];

    # ── Plugins (Nix downloads & links them — no :PackerSync needed) ──────────
    plugins = (with pkgs-unstable.vimPlugins; [

      # ── Colourscheme ─────────────────────────────────────────────────────────
      catppuccin-nvim

      # ── Fuzzy finding ────────────────────────────────────────────────────────
      telescope-nvim
      telescope-fzf-native-nvim   # compiled C extension, much faster sorting
      plenary-nvim                # Lua utility lib telescope depends on

      # ── File bookmarks ───────────────────────────────────────────────────────
      harpoon2                    # quick-access marks for files you actively edit

      # ── LSP ──────────────────────────────────────────────────────────────────
      nvim-lspconfig              # one-line setup per language server

      # ── Completion ───────────────────────────────────────────────────────────
      nvim-cmp                    # completion engine
      cmp-nvim-lsp                # source: LSP
      cmp-buffer                  # source: words in open buffers
      cmp-path                    # source: filesystem paths
      cmp-cmdline                 # source: : commands and / search
      luasnip                     # snippet engine (required by nvim-cmp)
      cmp_luasnip                 # cmp ↔ luasnip bridge
      friendly-snippets           # large snippet library (C++, Python, etc.)

      # ── AI completion ────────────────────────────────────────────────────────
      cmp-ai                      # fast inline AI completions (free tier available)

      # ── UI ───────────────────────────────────────────────────────────────────
      lualine-nvim                # statusline
      nvim-web-devicons           # file-type icons
      which-key-nvim              # popup showing available keymaps after <leader>
      gitsigns-nvim               # git change indicators in the gutter

      # ── Editing helpers ──────────────────────────────────────────────────────
      nvim-surround               # cs"' to change surrounding quotes, etc.
      comment-nvim                # gcc to toggle line comment
      nvim-autopairs              # auto-close brackets/quotes

      # ── Fun ──────────────────────────────────────────────────────────────────
      vim-be-good                 # :VimBeGood — drills for motions & operators

    ]) ++ [
      # ── Syntax / highlighting ────────────────────────────────────────────────
      pkgs-unstable.vimPlugins.nvim-treesitter.withAllGrammars
      pkgs-unstable.vimPlugins.nvim-treesitter-textobjects
    ];

    # ── init.lua ─────────────────────────────────────────────────────────────
    # This becomes ~/.config/nvim/init.lua.
    # Each `require` loads a file from ~/.config/nvim/lua/<name>.lua
    # (placed there by the xdg.configFile entries below).
    initLua = ''
      require('options')
      require('keymaps')
      require('plugins.ui')
      require('plugins.telescope')
      require('plugins.harpoon')
      require('plugins.treesitter')
      require('plugins.lsp')
      require('plugins.completion')
      require('plugins.cmp-ai')
      require('plugins.editing')
    '';
  };

  # ── Link Lua source files into ~/.config/nvim/lua/ ───────────────────────
  # Nix copies these from your repo at activation time.
  # Edit the .lua files, then run my-install — no plugin-manager dance needed.
  xdg.configFile = {
    "nvim/lua/options.lua".source            = ./options.lua;
    "nvim/lua/keymaps.lua".source            = ./keymaps.lua;
    "nvim/lua/plugins/ui.lua".source         = ./plugins/ui.lua;
    "nvim/lua/plugins/telescope.lua".source  = ./plugins/telescope.lua;
    "nvim/lua/plugins/harpoon.lua".source    = ./plugins/harpoon.lua;
    "nvim/lua/plugins/treesitter.lua".source = ./plugins/treesitter.lua;
    "nvim/lua/plugins/lsp.lua".source        = ./plugins/lsp.lua;
    "nvim/lua/plugins/completion.lua".source = ./plugins/completion.lua;
    "nvim/lua/plugins/ollama-completion.lua".source = ./plugins/ollama-completion.lua;
    "nvim/lua/plugins/editing.lua".source    = ./plugins/editing.lua;
  };
}
