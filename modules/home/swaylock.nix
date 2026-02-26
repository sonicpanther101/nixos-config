{ pkgs-stable, config, ... } : {
  programs.swaylock = {
    enable = true;
    package = pkgs-stable.swaylock-effects;
    settings = {
      clock = true;
      timestr = "%l:%M %p";
      datestr = "%d/%m/%y";
      screenshots = true;
      
      indicator = true;
      indicator-radius = 125;
      indicator-thickness = 10;
      
      effect-blur = "7x5";
      effect-vignette = "0.5:0.5";
      effect-pixelate = 5;
    };
  };
}