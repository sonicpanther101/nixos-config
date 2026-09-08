{ pkgs-stable, username, lib, ... } : {

  options.services = {
    kmscon.config = lib.mkOption {
      type = lib.types.anything;
      default = { };
      description = "Unused compatibility stub for Stylix's regreet target.";
    };
    displayManager.regreet = lib.mkOption {
      type = lib.types.anything;
      default = { };
      description = "Unused compatibility stub for Stylix's regreet target.";
    };
  };

  config.stylix = {
    enable = true;

    # Required
    image = pkgs-stable.fetchurl {
      url = "https://raw.githubusercontent.com/sonicpanther101/RaspberryPi-Elecrow-Kit/main/nixos.png";
      sha256 = "sha256-vWh3HJe9s/q9pb7oMsfRG27124a+X5bbbJVa32UrZSs=";
    };
    # targets.grub.useImage = true;
    autoEnable = true;
    
    targets = {
      grub.enable = false;
      regreet.enable = false;
      kmscon.enable = false;
    };

    polarity = "dark";
    base16Scheme = "${pkgs-stable.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    opacity.terminal = 0.55;

    fonts = {
      serif = {
        package = pkgs-stable.dejavu_fonts;
        name = "DejaVu Serif";
      };

      sansSerif = {
        package = pkgs-stable.dejavu_fonts;
        name = "DejaVu Sans";
      };

      monospace = {
        package = pkgs-stable.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };

      emoji = {
        package = pkgs-stable.noto-fonts-monochrome-emoji;
        # package = pkgs-stable.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        applications = 12;
        desktop = 10;
        popups = 10;
        terminal = 12;
      };
    };
  
    cursor = {
      # package = pkgs-stable.catppuccin-cursors.mochaBlue;
      package = pkgs-stable.catppuccin-cursors.mochaDark;
      # name = "catppuccin-mocha-blue-cursors";
      name = "catppuccin-mocha-dark-cursors";
      size = 22;
    };
  };

  config.home-manager.users.${username} = {
    stylix.targets = {
      vscode.enable = false;
      vscodium.enable = false;
      # hyprland.enable = false;
      qt.enable = false;
      hyprlock.enable = false;
    };
  };
}
