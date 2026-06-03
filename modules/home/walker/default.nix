{ ... } : {
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
  
  xdg.configFile."elephant/menus/wallpapers.lua".source = ./wallpapers.lua;
  xdg.configFile."elephant/menus/aliases.lua".source = ./aliases.lua;
  xdg.configFile."elephant/menus/keybinds.lua".source = ./keybinds.lua;
  xdg.configFile."walker/themes/catppuccin/style.css".source = ./style.css;
}