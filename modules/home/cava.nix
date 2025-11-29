{ inputs, pkgs-stable, ... }: 
{
  # Audio visualiser
  programs.cava = {
    enable = true;
    package = pkgs-stable.cava;
  };
  
  # https://github.com/catppuccin/cava
  home.file.".config/cava/config".text = ''
    # custom cava config
  '' + builtins.readFile "${inputs.catppuccin-cava}/themes/mocha-transparent.cava";
}