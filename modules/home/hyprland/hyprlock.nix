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
        # TIME
        monitor = "";
        text = "cmd[update:1000] date +'%l:%M %p'";
        font_size = 65;
        font_family = "$font";

        position = "0, -100";
        valign = "top";
      } {
        # DATE
        monitor = "";
        text = "cmd[update:60000] date +'%A, %e %B %Y' | sed 's|  | |'"; # update every 60 seconds
        font_size = 25;
        font_family = "$font";

        position = "0, -250";
        valign = "top";
      } {
        # Weather
        text = "cmd[update:600000] weather";
        position = "0, 250";
        font_size = 18;
        font-family = "JetBrainsMono Nerd Font";
      } {
        # GitHub
        text = "cmd[update:3600000] github-contributions";
        position = "0, 200";
        font_size = 16;
        font-family = "JetBrainsMono Nerd Font";
      } {
        # WakaTime
        text = "cmd[update:300000] wakatime-cli --today";
        position = "0, 150";
        font_size = 16;
        font-family = "JetBrainsMono Nerd Font";
      }];
    };
  };
}