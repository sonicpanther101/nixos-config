{ pkgs, lib, config, inputs, ... }: 
{
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      clock = true;
      timestr = "%l:%M %p";
      datestr = "%d/%m/%y";
      screenshots = true;
      
      indicator = true;
      indicator-radius = 125;
      indicator-thickness = 7;
      
      effect-blur = "7x5";
      effect-vignette = "0.5:0.5";
      effect-pixelate = 5;
      
      bs-hl-color="f5e0dc";
      caps-lock-bs-hl-color="f5e0dc";
      caps-lock-key-hl-color="a6e3a1";
    };
  };
}