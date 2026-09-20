{ pkgs-stable, lib, host, hasPinLogin ? false, pinLoginCode ? "", pinLoginLength ? 4, ... }:
let
  # 1. Define base widget sizes (calibrated for primary 1440p @ 1.3333x display)
  baseConfig = {
    input = { width = 200; height = 50; posY = -80; outline = 4; };
    time  = { fontSize = 65; posY = -320; };
    date  = { fontSize = 22; posY = -250; };
    wx    = { fontSize = 16; posX = 600;  };
    gh    = { fontSize = 14; posX = -600; };
    pin   = { buttonSize = 100; spacing = 115; baseY = -40; indicatorPosY = -190; };
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

  # 2b. PIN-login keypad: 10 round number images (standard 3x4 phone layout,
  # 0 centered on the bottom row) that each fire my-hyprlock-pin, plus a
  # dot-progress / status label driven entirely by that script.
  pinButtonImage = digit:
    pkgs-stable.runCommand "hyprlock-pin-btn-${digit}.png" {
      nativeBuildInputs = [ pkgs-stable.imagemagick pkgs-stable.dejavu_fonts ];
    } ''
      magick -size 130x130 xc:none \
        -fill "#1e1e2e" -draw "circle 65,65 65,5" \
        -fill none -stroke "#89b4fa" -strokewidth 4 -draw "circle 65,65 65,5" \
        -fill "#cdd6f4" -font "${pkgs-stable.dejavu_fonts}/share/fonts/truetype/DejaVuSans-Bold.ttf" \
        -pointsize 48 -gravity center -annotate +0+0 "${digit}" \
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
    # hyprlock's Y axis runs opposite normal screen coords (confirmed by testing on
    # this setup), so the vertical offset is negated here relative to how X is handled.
    position = "${toString (builtins.floor ((entry.c - 1) * baseConfig.pin.spacing * scale))}, ${toString (builtins.floor (-1 * (baseConfig.pin.baseY + entry.r * baseConfig.pin.spacing) * scale))}";
    halign = "center";
    valign = "center";
    reload_time = -1;
    onclick = "PIN_LOGIN_CODE=${pinLoginCode} PIN_LOGIN_LENGTH=${toString pinLoginLength} my-hyprlock-pin press ${entry.d}";
  };

  mkPinIndicator = monitorName: scale: {
    monitor = monitorName;
    text = "cmd[update:150] my-hyprlock-pin status";
    font_size = builtins.floor (28 * scale);
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
    { name = "";         scale = 1.0; } # Catch-all for laptop display (eDP-1)
  ];

  activeMonitors = if (host == "desktop") then desktopMonitors else laptopMonitors;

  # 4. Generate widget groups explicitly ordered by execution priority across all monitors
  inputFields   = map (m: mkInput m.name m.scale) activeMonitors;
  clockLabels   = builtins.concatLists (map (m: [ (mkTime m.name m.scale) (mkDate m.name m.scale) ]) activeMonitors);
  weatherLabels = map (m: mkWeather m.name m.scale) activeMonitors;
  githubLabels  = map (m: mkGithub m.name m.scale) activeMonitors;

  pinButtons   = if hasPinLogin then builtins.concatLists (map (m: map (mkPinButton m.name m.scale) pinLayout) activeMonitors) else [];
  pinLabels    = if hasPinLogin then map (m: mkPinIndicator m.name m.scale) activeMonitors else [];

  # hyprlock never implements the Wayland touch protocol, so taps on the pin
  # buttons don't register as clicks. This little daemon watches the raw
  # touchscreen and turns a plain single-finger tap into a real cursor
  # move + click via hyprctl/wlrctl. Only built/run when hasPinLogin is on,
  # and only for as long as hyprlock itself is running (see systemd units
  # below).
  touchClickScript = pkgs-stable.writers.writePython3Bin "my-hyprlock-touch-click" {
    libraries = [ pkgs-stable.python3Packages.evdev ];
  } (builtins.readFile ./hyprlock-touch-click.py);

in {
  home.packages = lib.optionals hasPinLogin [ pkgs-stable.wlrctl ];

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

      # Hyprlock evaluates input-fields first, followed by labels in array order across displays.
      # When hasPinLogin is on, there's no input-field or PAM involved at all: the 10 numbered
      # image buttons each call my-hyprlock-pin, which tracks presses itself and pkills hyprlock
      # on a correct PIN. The label below just shows dot/status feedback for that script.
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
    } // lib.optionalAttrs hasPinLogin {
      # Bring the touch-click helper up alongside hyprlock. It's tied back
      # to this unit (BindsTo/PartOf below) so it also goes down with it.
      Wants = [ "my-hyprlock-touch-click.service" ];
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
      Description = "Turn touchscreen taps into clicks while hyprlock is active";
      PartOf = [ "hyprlock.service" ];
      BindsTo = [ "hyprlock.service" ];
      After = [ "hyprlock.service" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${touchClickScript}/bin/my-hyprlock-touch-click";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };
}
