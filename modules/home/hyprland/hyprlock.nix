{ pkgs-stable, lib, host, hasPinLogin ? false, pinLoginCode ? "", pinLoginLength ? 4, ... }:
let
  myTouchClickPkg = pkgs-stable.writeShellApplication {
    name = "my-hyprlock-touch-click";
    runtimeInputs = [ pkgs-stable.wlrctl pkgs-stable.libinput pkgs-stable.socat pkgs-stable.gawk pkgs-stable.gnused ];
    text = builtins.readFile ../scripts/my-hyprlock-touch-click.sh;
  };

  # 1. Define base widget sizes (calibrated for primary 1440p @ 1.3333x display)
  # Added pinpadScale to scale the entire PIN pad geometry by 1.25x
  pinpadScale = 1.25;

  baseConfig = {
    input = { width = 200; height = 50; posY = -80; outline = 4; };
    time  = { fontSize = 65; posY = -320; };
    date  = { fontSize = 22; posY = -250; };
    wx    = { fontSize = 16; posX = 600;  };
    gh    = { fontSize = 14; posX = -600; };
    pin   = { 
      buttonSize = 100 * pinpadScale; 
      spacing = 115 * pinpadScale; 
      baseY = -40 * pinpadScale; 
      indicatorPosY = -190 * pinpadScale; 
    };
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

  # 2b. High-resolution PIN-login keypad images
  # Canvas resolution doubled from 130x130 to 260x260 for high DPI crispness
  pinButtonImage = digit:
    pkgs-stable.runCommand "hyprlock-pin-btn-${digit}.png" {
      nativeBuildInputs = [ pkgs-stable.imagemagick pkgs-stable.dejavu_fonts ];
    } ''
      magick -size 260x260 xc:none \
        -fill "#1e1e2e" -draw "circle 130,130 130,10" \
        -fill none -stroke "#89b4fa" -strokewidth 8 -draw "circle 130,130 130,10" \
        -fill "#cdd6f4" -font "${pkgs-stable.dejavu_fonts}/share/fonts/truetype/DejaVuSans-Bold.ttf" \
        -pointsize 96 -gravity center -annotate +0+0 "${digit}" \
        "$out"
    '';

  pinLayout = [
    { d = "1"; c = 0; r = 0; } { d = "2"; c = 1; r = 0; } { d = "3"; c = 2; r = 0; }
    { d = "4"; c = 0; r = 1; } { d = "5"; c = 1; r = 1; } { d = "6"; c = 2; r = 1; }
    { d = "7"; c = 0; r = 2; } { d = "8"; c = 1; r = 2; } { d = "9"; c = 2; r = 2; }
                               { d = "0"; c = 1; r = 3; }
  ];

  mkPinButton = monitorName: scale: entry: {
    monitor = monitorName;
    path = "${pinButtonImage entry.d}";
    size = builtins.floor (baseConfig.pin.buttonSize * scale);
    rounding = -1;
    position = "${toString (builtins.floor ((entry.c - 1) * baseConfig.pin.spacing * scale))}, ${toString (builtins.floor (-1 * (baseConfig.pin.baseY + entry.r * baseConfig.pin.spacing) * scale))}";
    halign = "center";
    valign = "center";
    reload_time = -1;
    onclick = "PIN_LOGIN_CODE=${pinLoginCode} PIN_LOGIN_LENGTH=${toString pinLoginLength} my-hyprlock-pin press ${entry.d}";
  };

  mkPinIndicator = monitorName: scale: {
    monitor = monitorName;
    text = "cmd[update:150] my-hyprlock-pin status";
    font_size = builtins.floor (28 * pinpadScale * scale);
    font_family = "$font";
    position = "0, ${toString (builtins.floor (-1 * baseConfig.pin.indicatorPosY * scale))}";
    halign = "center";
    valign = "center";
    font_color = "rgb(205, 214, 244)";
  };

  # 3. Define monitor mappings
  desktopMonitors = [
    { name = "DP-1";     scale = 1.0; }
    { name = "HDMI-A-1"; scale = 0.75; }
  ];

  laptopMonitors = [
    { name = "";         scale = 1.0; }
  ];

  activeMonitors = if (host == "desktop") then desktopMonitors else laptopMonitors;

  # 4. Generate widget groups
  inputFields   = map (m: mkInput m.name m.scale) activeMonitors;
  clockLabels   = builtins.concatLists (map (m: [ (mkTime m.name m.scale) (mkDate m.name m.scale) ]) activeMonitors);
  weatherLabels = map (m: mkWeather m.name m.scale) activeMonitors;
  githubLabels  = map (m: mkGithub m.name m.scale) activeMonitors;

  pinButtons   = if hasPinLogin then builtins.concatLists (map (m: map (mkPinButton m.name m.scale) pinLayout) activeMonitors) else [];
  pinLabels    = if hasPinLogin then map (m: mkPinIndicator m.name m.scale) activeMonitors else [];

in {

  home.packages = [ myTouchClickPkg ];

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

      input-field = if hasPinLogin then [ ] else inputFields;
      image       = pinButtons;
      label       = clockLabels ++ weatherLabels ++ githubLabels ++ pinLabels;
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

  systemd.user.services.my-hyprlock-touch-click = lib.mkIf hasPinLogin {
    Unit = {
      Description = "Turn touchscreen taps into clicks background service";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${myTouchClickPkg}/bin/my-hyprlock-touch-click";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };
}
