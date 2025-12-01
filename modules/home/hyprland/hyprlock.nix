{ ... } : {
  programs.hyprlock = {
    enable = true;
    settings = {

      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };

       animations = {
        enabled = true;
        fade_in = {
          duration = 300;
          bezier = "easeOutQuint";
        };
        fade_out = {
          duration = 300;
          bezier = "easeOutQuint";
        };
      };

      background = {
        path = "screenshot";
        blur_passes = 3;
        blur_size = 8;
      };
    };
  };
}