{ pkgs-stable, config, ... } : {
  programs.hyprlock = {
    enable = true;
    package = pkgs-stable.hyprlock;
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

      input-field = {
        size = "0, 0";
        position = "0, 0";
        monitor = "";
        # font_color = "rgb(202, 211, 245)";
        # inner_color = "rgb(91, 96, 120)";
        # outer_color = "rgb(24, 25, 38)";
        outline_thickness = 0;
        placeholder_text = "";
        shadow_passes = 0;
      };
    };
  };
}