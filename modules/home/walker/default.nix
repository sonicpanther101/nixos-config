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
        default = [
          "desktopapplications"
          "calc"
          "runner"
          "websearch"
        ];
        prefixes = [
          { prefix = "+"; provider = "menus:wallpapers"; }
        ];
      };

      themes."catppuccin" = {
        style = builtins.readFile ./style.css;
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
  xdg.configFile."elephant/menus/wallpapers.lua".text = ''
    Name = "wallpapers"
    NamePretty = "Wallpapers"
    Icon = "preferences-desktop-wallpaper"
    Cache = false
    Action = "my-rwall -n %VALUE%"

    function GetEntries()
      local entries = {}
      local preview_dir = os.getenv("HOME") .. "/Pictures/wallpapers/preview"
      local handle = io.popen("ls '" .. preview_dir .. "'")
      if handle then
        for filename in handle:lines() do
          local clean = filename:match("(.+)%.") or filename
          local display = clean:gsub("[_%-]", " ")
          table.insert(entries, {
            Text = display,
            Value = filename,
            Icon = preview_dir .. "/" .. filename,
            Preview = preview_dir .. "/" .. filename,
            PreviewType = "file"
          })
        end
        handle:close()
      end
      return entries
    end
  '';
}