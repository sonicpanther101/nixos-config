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

      label = [{
        # TIME
        monitor = "";
        text = "$TIME12"; # ref. https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/#variable-substitution
        font_size = 65;
        font_family = "$font";

        position = "0, -10";
        valign = "top";
      } {
        # DATE
        monitor = "";
        text = "cmd[update:3600000] date +'%A, %d %B %Y'"; # update every 60 seconds
        font_size = 25;
        font_family = "$font";

        position = "0, -150";
        valign = "top";
      }];
    };
  };
}