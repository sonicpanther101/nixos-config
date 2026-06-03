{ pkgs-stable, inputs, config, ... } : {
  imports = [
    inputs.walker.homeManagerModules.default
  ];
  programs.walker = {
    enable = true;
    runAsService = true;

    config = {
      theme = "custom";
      force_keyboard_focus = true;
      selection_wrap = true;
      hide_action_hints = true;
      close_when_open = true;
      click_to_close = true;
      global_argument_delimiter = "#";
      exact_search_prefix = "'";

      placeholders = {
        "default" = {
          input = "Search...";
          list = "No Results";
        };
      };

      providers = {
        max_results = 256;
        ignore_preview = [
          "desktopapplications"
          "windows"
        ];
        default = [
          "desktopapplications"
          "windows"
        ];
        prefixes = [
          {
            prefix = "/";
            provider = "providerlist";
          }
          {
            prefix = ".";
            provider = "files";
          }
          {
            prefix = ":";
            provider = "symbols";
          }
          {
            prefix = "=";
            provider = "calc";
          }
          {
            prefix = "@";
            provider = "websearch";
          }
          {
            prefix = "$";
            provider = "clipboard";
          }
          {
            prefix = "+";
            provider = "menus:wallpapers";
          }
        ];
      };

      emergencies = [
        {
          text = "Restart Walker";
          command = "systemctl --user restart walker.service";
        }
      ];
    };

    themes."custom" = {
      style = import ./style.nix {inherit config;};
      layouts = {
        "layout" = import ./layout.nix;
        "item_calc" = import ./item_calc.nix;
        "item_menus-wallpapers" = import ./item_menus_wallpapers.nix;
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