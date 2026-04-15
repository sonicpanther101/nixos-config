{ pkgs-unstable, ... } : {
  programs.swaylock = {
    enable = true;
    package = pkgs-unstable.swaylock;

    settings = {
      clock = true;
      timestr = "%l:%M %p";
      datestr = "%d/%m/%y";

      screenshots = true;

      indicator = true;
      indicator-radius = 125;
      indicator-thickness = 10;

      # optional nice additions
      fade-in = 0.3;
      grace = 2;
    };
  };
}