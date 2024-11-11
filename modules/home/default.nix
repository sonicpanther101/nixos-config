{inputs, username, host, ...}: {
  imports =
       [(import ./aseprite/aseprite.nix)]         # pixel art editor
    ++ [(import ./audacious/audacious.nix)]       # music player
    ++ [(import ./bat.nix)]                       # better cat command
    ++ [(import ./cava.nix)]                      # audio visualizer
    ++ [(import ./discord.nix)]                   # discord with catppuccin theme
    ++ [(import ./gaming.nix)]                    # packages related to gaming
    ++ [(import ./git.nix)]                       # version control
    ++ [(import ./gtk.nix)]                       # gtk theme
    ++ [(import ./hyprland)]                      # window manager
    ++ [(import ./kitty.nix)]                     # terminal
    ++ [(import ./micro.nix)]                     # nano replacement
    ++ [(import ./mimelist.nix)]
    ++ [(import ./packages.nix)]                  # other packages
    # ++ [(import ./retroarch.nix)]
    ++ [(import ./scripts/scripts.nix)]           # personal scripts
    ++ [(import ./starship.nix)]                  # shell prompt
    ++ [(import ./swaylock.nix)]                  # lock screen
    ++ [(import ./vscodium.nix)]                  # vscode fork
    ++ [(import ./ags)]                           # status bar
    ++ [(import ./zsh.nix)];                      # shell
    # ++ [(import ./end_4)];
}