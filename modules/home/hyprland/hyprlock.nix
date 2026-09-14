{ pkgs-stable, host, ... }:
let
  # 1. Define base widget sizes (calibrated for primary 1440p @ 1.3333x display)
  baseConfig = {
    input = { width = 200; height = 50; posY = -80; outline = 4; };
    time  = { fontSize = 65; posY = -320; };
    date  = { fontSize = 22; posY = -250; };
    wx    = { fontSize = 16; posX = 600;  };
    gh    = { fontSize = 14; posX = -600; };
  };

  # 2. Modular helper functions per widget type
  mkInput = monitorName: scale: {
    monitor = monitorName;
    size = "${toString (builtins.floor (baseConfig.input.width * scale))}, ${toString (builtins.floor (baseConfig.input.height * scale))}";
    position = "0, ${toString (builtins.floor (baseConfig.input.posY * scale))}";
    dots_center = true;
    fade_on_empty = false;
    font_color = "rgb(205, 214, 244)";
    inner_color = "rgb(30, 30, 46)";
    outer_color = "rgb(137, 180, 250)";
    outline_thickness = builtins.floor (baseConfig.input.outline * scale);
    placeholder_text = "Password...";
    shadow_passes = 2;
  };

  mkTime = monitorName: scale: {
    monitor = monitorName;
    text = "cmd[update:1000] date +'%l:%M %p'";
    font_size = builtins.floor (baseConfig.time.fontSize * scale);
    font_family = "$font";
    position = "0, ${toString (builtins.floor (baseConfig.time.posY * scale))}";
    halign = "center";
    valign = "top";
  };

  mkDate = monitorName: scale: {
    monitor = monitorName;
    text = "cmd[update:60000] date +'%A, %e %B %Y' | sed 's|  | |'";
    font_size = builtins.floor (baseConfig.date.fontSize * scale);
    font_family = "$font";
    position = "0, ${toString (builtins.floor (baseConfig.date.posY * scale))}";
    halign = "center";
    valign = "top";
  };

  mkWeather = monitorName: scale: {
    monitor = monitorName;
    text = "cmd[update:600000] my-weather";
    font_size = builtins.floor (baseConfig.wx.fontSize * scale);
    font_family = "JetBrainsMono Nerd Font";
    position = "${toString (builtins.floor (baseConfig.wx.posX * scale))}, 0";
    halign = "center";
    valign = "center";
  };

  mkGithub = monitorName: scale: {
    monitor = monitorName;
    text = "cmd[update:3600000] my-github-contributions";
    font_size = builtins.floor (baseConfig.gh.fontSize * scale);
    font_family = "JetBrainsMono Nerd Font";
    position = "${toString (builtins.floor (baseConfig.gh.posX * scale))}, 0";
    halign = "center";
    valign = "center";
  };

  # 3. Define monitor mappings
  desktopMonitors = [
    { name = "DP-1";     scale = 1.0; }
    { name = "HDMI-A-1"; scale = 0.75; }
  ];

  laptopMonitors = [
    { name = "";         scale = 1.0; } # Catch-all for laptop display (eDP-1)
  ];

  activeMonitors = if (host == "desktop") then desktopMonitors else laptopMonitors;

  # 4. Generate widget groups explicitly ordered by execution priority across all monitors
  inputFields   = map (m: mkInput m.name m.scale) activeMonitors;
  clockLabels   = builtins.concatLists (map (m: [ (mkTime m.name m.scale) (mkDate m.name m.scale) ]) activeMonitors);
  weatherLabels = map (m: mkWeather m.name m.scale) activeMonitors;
  githubLabels  = map (m: mkGithub m.name m.scale) activeMonitors;

in {
  programs.hyprlock = {
    enable = true;
    package = pkgs-stable.hyprlock;
    settings = {

      general = {
        hide_cursor = false;
      };

      background = map (m: {
        monitor = m.name;
        path = "screenshot";
        blur_passes = 3;
        blur_size = 8;
      }) activeMonitors;

      # Hyprlock evaluates input-fields first, followed by labels in array order across displays
      input-field = inputFields;
      label       = clockLabels ++ weatherLabels ++ githubLabels;
    };
  };

  systemd.user.services.hyprlock = {
    Unit = {
      Description = "Hyprlock screen locker";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs-stable.hyprlock}/bin/hyprlock";
      Restart = "on-failure";
      RestartSec = 1;
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
    };
  };
}
