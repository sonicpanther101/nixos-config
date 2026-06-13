{ pkgs-stable, ... } : {
  programs.hyprlock = {
    enable = true;
    package = pkgs-stable.hyprlock;
    settings = {

      general = {
        hide_cursor = false;
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
        # TIME (top center)
        monitor = "";
        text = "cmd[update:1000] date +'%l:%M %p'";
        font_size = 65;
        font_family = "$font";

        position = "0, -320";
        halign = "center";
        valign = "top";
      } {
        # DATE (top center under time)
        monitor = "";
        text = "cmd[update:60000] date +'%A, %e %B %Y' | sed 's|  | |'";
        font_size = 22;
        font_family = "$font";

        position = "0, -250";
        halign = "center";
        valign = "top";
      } {
        # WEATHER (right side, tall block)
        monitor = "";
        text = "cmd[update:600000] my-weather";
        font_size = 16;
        font_family = "JetBrainsMono Nerd Font";

        position = "600, 0";
        halign = "center";
        valign = "center";
      } {
        # GITHUB (left upper)
        monitor = "";
        text = "cmd[update:3600000] my-github-contributions";
        font_size = 14;
        font_family = "JetBrainsMono Nerd Font";

        position = "-600, 0";
        halign = "center";
        valign = "center";
      } {
        # WAKATIME (left lower)
        monitor = "";
        text = "cmd[update:300000] echo \"Coded for $(wakatime-cli --today) today\"";
        font_size = 14;
        font_family = "JetBrainsMono Nerd Font";

        position = "-600, -200";
        halign = "center";
        valign = "center";
      }];
    };
  };
}