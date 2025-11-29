{ inputs, username, host, pkgs-stable, ... } : {

  programs.nh = {
    enable = true;
    clean.enable = true;
  };

  # Temporary notifications daemon to shut grimblast up
  services.mako.enable = true;

  # Cat alternative
  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR";
    };
  };

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