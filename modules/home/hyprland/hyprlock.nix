{ pkgs-stable, config, ... } : {
  programs.hyprlock = {
    enable = true;
    package = pkgs-stable.hyprlock;
    settings = {

      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };

      background = {
        path = "screenshot";
        blur_passes = 3;
        blur_size = 8;
      };

      input-field = {
        size = "200, 50";
        position = "0, -80";
        monitor = "";
        dots_center = true;
        fade_on_empty = false;
        font_color = "rgb(205, 214, 244)";
        inner_color = "rgb(30, 30, 46)";
        outer_color = "rgb(137, 180, 250)";
        outline_thickness = 4;
        placeholder_text = "Password...";
        shadow_passes = 2;
      };

      label = [{
        # TIME
        monitor = "";
        text = "cmd[update:1000] date +'%l:%M %p'";
        font_size = 65;
        font_family = "$font";
        font_color = "rgb(205, 214, 244)";

        position = "0, -100";
        valign = "top";
      } {
        # DATE
        monitor = "";
        text = "cmd[update:60000] date +'%A, %e %B %Y'"; # update every 60 seconds
        font_size = 25;
        font_family = "$font";
        font_color = "rgb(205, 214, 244)";

        position = "0, -250";
        valign = "top";
      }];
    };
  };
}