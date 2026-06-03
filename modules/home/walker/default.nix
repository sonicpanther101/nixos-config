{ pkgs-stable, pkgs-unstable, ... }: {

  programs.walker = {
    enable = true;
    runAsService = true;
    config = {
      theme = "catppuccin";
      force_keyboard_focus = true;
      placeholders = {
        "default" = {
          input = "Search...";
          list = "No Results";
        };
      };
      providers = {
        max_results = 256;
        default = [
          "desktopapplications"
          "calc"
          "runner"
          "websearch"
        ];
        prefixes = [
          { prefix = "+"; provider = "menus:wallpapers"; }
          { prefix = "#"; provider = "menus:aliases"; }
        ];
        actions.fallback = [
          { action = "runAlias"; label = "run in kitty"; bind = "shift Return"; after = "Close"; }
          { action = "copyAlias"; label = "copy command"; bind = "Return"; after = "Close"; }
        ];
      };
      builtins.websearch = {
        enabled = true;
        entries = [
          { name = "Brave";  url = "https://search.brave.com/search?q={}"; prefix = "b"; switcher_only = false; }
          { name = "GitHub"; url = "https://github.com/search?q={}";       prefix = "g"; switcher_only = false; }
        ];
      };
    };
  };

  xdg.configFile."elephant/clipboard.toml".text =
    let
      smartPasteScript = pkgs-stable.writeShellScript "smart-paste" ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Copy content to clipboard first (reads from stdin)
        ${pkgs-stable.wl-clipboard}/bin/wl-copy

        # Small delay for clipboard to sync and Walker window to close
        sleep 0.15

        # Get focused window class via hyprctl
        focused=$(${pkgs-unstable.hyprland}/bin/hyprctl activewindow -j \
          | ${pkgs-stable.jq}/bin/jq -r '.class // ""' 2>/dev/null)

        # Terminal detection - use Ctrl+Shift+V, else Ctrl+V
        case "$focused" in
          kitty|Kitty|ghostty|Ghostty|alacritty|Alacritty|foot|Foot|wezterm|WezTerm|xterm|XTerm)
            ${pkgs-stable.wtype}/bin/wtype -M ctrl -M shift v
            ;;
          *)
            ${pkgs-stable.wtype}/bin/wtype -M ctrl v
            ;;
        esac
      '';
    in ''
      icon = "edit-paste"
      min_score = 30
      max_items = 500
      recopy = true
      ignore_symbols = false
      auto_cleanup = 0
      command = "${smartPasteScript}"
    '';

  xdg.configFile."elephant/clipboard_copy.toml".text = ''
    icon = "edit-copy"
    min_score = 30
    max_items = 500
    recopy = true
    ignore_symbols = false
    auto_cleanup = 0
  '';

  xdg.configFile."elephant/menus/wallpapers.lua".source = ./wallpapers.lua;
  xdg.configFile."elephant/menus/aliases.lua".source = ./aliases.lua;
  xdg.configFile."elephant/menus/keybinds.lua".source = ./keybinds.lua;
  xdg.configFile."walker/themes/catppuccin/style.css".source = ./style.css;
}