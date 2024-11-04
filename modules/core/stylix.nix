{ pkgs, inputs, username, lib, ... }: 
{
    stylix = {
        enable = true;
        image = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/sonicpanther101/RaspberryPi-Elecrow-Kit/main/nixos.png";
            sha256 = "sha256-vWh3HJe9s/q9pb7oMsfRG27124a+X5bbbJVa32UrZSs=";
        };
        targets.grub.useImage = true;

        polarity = "dark";
        base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
        opacity.terminal = 0.55;

        fonts = {
            serif = {
                package = pkgs.nerdfonts;
                name = "JetBrainsMono Nerd Font";
            };

            sansSerif = {
                package = pkgs.nerdfonts;
                name = "JetBrainsMono Nerd Font";
            };

            monospace = {
                package = pkgs.nerdfonts;
                name = "JetBrainsMono Nerd Font";
            };

            emoji = {
                package = pkgs.noto-fonts-emoji;
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
            # package = pkgs.catppuccin-cursors.mochaBlue;
            package = pkgs.catppuccin-cursors.mochaDark;
            # name = "catppuccin-mocha-blue-cursors";
            name = "catppuccin-mocha-dark-cursors";
            size = 18;
        };
    };

    home-manager.users.${username} = {
        stylix = {
            targets.vscode.enable = false;
        };
    };
}