{ isHighPower, isLaptop, isServer, lib, inputs, pkgs-stable, config, ... } : let
  # Dynamic output-device menu for the volume module (see audio-menu.sh).
  audioMenu = pkgs-stable.writeShellScriptBin "my-audio-menu" ''
    export PATH=${lib.makeBinPath (with pkgs-stable; [
      coreutils gnused gnugrep jq pipewire wireplumber pulseaudio systemd
    ])}:$PATH
    ${builtins.readFile ./audio-menu.sh}
  '';
  audioMenuFile = "${config.home.homeDirectory}/.cache/waybar/audio-menu.xml";
  maxAudioSinks = 12;

  # Rotate the focused monitor (see rotate-monitor.sh).
  rotateMonitor = pkgs-stable.writeShellScript "rotate-monitor" ''
    export PATH=${lib.makeBinPath [ pkgs-stable.jq ]}:$PATH
    ${builtins.readFile ./rotate-monitor.sh}
  '';
in {
  home.packages = [ audioMenu ];

  systemd.user.services = {
    # Make sure the menu XML exists before waybar reads it
    waybar.Service.ExecStartPre = "-${audioMenu}/bin/my-audio-menu gen";

    # Regenerate the menu + reload waybar when output devices come and go
    waybar-audio-menu = {
      Unit = {
        Description = "Keep the waybar volume menu in sync with PipeWire outputs";
        After = [ "pipewire.service" "pipewire-pulse.service" "wireplumber.service" "waybar.service" ];
        Wants = [ "pipewire-pulse.service" ];
      };
      Service = {
        ExecStart = "${audioMenu}/bin/my-audio-menu watch";
        Restart = "always";
        RestartSec = 2;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };

  programs.waybar = {
    enable = true;
    package = inputs.waybar-git.packages.${pkgs-stable.stdenv.hostPlatform.system}.default;
    systemd = {
      enable = true;
      targets = [ "graphical-session.target" ];
    };
    settings = {
      mainBar = {
        layer = "bottom";
        position = "top";
        height = 30;

        modules-left = [ "custom/menu" "hyprland/workspaces" "custom/backup" ];
        modules-center = [ "custom/pomodoro" "custom/clock" ];
        modules-right = [
          "custom/mpris"
          "image#album-art"
        ] ++ lib.optionals isHighPower [
          "cava"
        ] ++ [
          "wireplumber"
          "tray"
        ] ++ lib.optionals isLaptop [
          "backlight"
        ] ++ [
          "custom/keyboard"
          "idle_inhibitor"
        ] ++ lib.optionals isLaptop [
          "battery"
        ];

        battery = {
          states = {
            warning = 50;
            critical = 25;
          };
          format = "{icon}  {capacity}%";
          format-charging = " {icon}  {capacity}%";
          format-full = " {icon}  {capacity}%";
          format-time = "{H}h{M}m";
          format-icons = ["" "" "" "" ""];
          tooltip-format = "{time}";
        };

        "hyprland/workspaces" = {
          format = "<sub>{icon}</sub>";
          format-icons = {
            empty = "";
            active = "";
            visible = "";
            default = "";
            urgent = "";
          };
          persistent-workspaces = {
            "HDMI-A-1" = if isServer then [ 1 2 3 4 5 ] else [ 11 12 13 14 15 ];
            "DP-1" = [ 1 2 3 4 5 ];
            "eDP-1" = [ 1 2 3 4 5 ];
          };
          active-only = true;
          all-outputs = false;
          on-scroll-up   = "hyprctl dispatch 'require(\"plugins.split-monitor-workspaces\").cycle_workspaces(\"next\")'";
          on-scroll-down = "hyprctl dispatch 'require(\"plugins.split-monitor-workspaces\").cycle_workspaces(\"prev\")'";
        };

        "custom/keyboard" = {
          format = "⌨";
          tooltip = false;
          on-click = "my-toggle-keyboard";
        };

        "image#album-art" = {
          exec = "my-player-art";
          interval = 5;
          on-click = "playerctl -p $(cat \${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player) play-pause";
          on-scroll-up = "playerctl -p $(cat \${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player) next";
          on-scroll-down = "playerctl -p $(cat \${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player) previous";
          size = 24;
          tooltip = false;
        };

        "custom/pomodoro" = {
          exec = ''
            if [ -f /tmp/pomodoro-waybar ] &&
              [ $(( $(date +%s) - $(stat -c %Y /tmp/pomodoro-waybar) )) -lt 3 ]
            then
              cat /tmp/pomodoro-waybar
            fi
          '';
          interval = 1;
          return-type = "plain";
          tooltip = false;
        };

        "custom/mpris" = {
          exec = "my-mpris-waybar";
          tooltip = false;
          on-click = "playerctl -p $(cat \${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player) play-pause";
          on-scroll-up = "playerctl -p $(cat \${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player) next";
          on-scroll-down = "playerctl -p $(cat \${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player) previous";
        };

        mpris = {
          format = "{player_icon} {dynamic}";
          format-paused = "{status_icon} {dynamic}";
          player-icons = {
            default = " ⏸";
          };
          status-icons = {
            paused = " ▶";
          };
          tooltip = false;
          on-click = "playerctl -p $(cat \${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player) play-pause";
          on-scroll-up = "playerctl -p $(cat \${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player) next";
          on-scroll-down = "playerctl -p $(cat \${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player) previous";
          max-length = 45;
        };

        "custom/menu" = {
          format = "";
          tooltip = "Power & Screen Rotation";
          menu = "on-click";
          menu-file = "${./menu.xml}";
          menu-actions = {
            lock = "systemctl --user restart hyprlock.service";
            sleep = "my-sleep";
            sleep-1 = "my-sleep";
            poweroff = "hyprshutdown -t 'Shutting down...' --post-cmd 'my-shutdown'";
            reboot = "hyprshutdown -t 'Restarting...' --post-cmd 'reboot'";

            wallpaper = "walker -m menus:wallpapers";
            keybinds = "walker -m menus:keybinds";
            aliases = "walker -m menus:aliases";

            upright = "${rotateMonitor} 0";
            left = "${rotateMonitor} 1";
            upside = "${rotateMonitor} 2";
            right = "${rotateMonitor} 3";

            cw = "${rotateMonitor} cw";
            ccw = "${rotateMonitor} ccw";
            flip = "${rotateMonitor} flip";
          };
        };

        wireplumber = {
          format = "{volume}% {icon}";
          format-muted = "0% 󰝟";
          on-click = "pamixer -t";
          format-icons = ["󰕿" "󰖀" "󰕾"];
          on-scroll-up   = if isLaptop then "pamixer -d 2" else "pamixer -i 2";
          on-scroll-down = if isLaptop then "pamixer -i 2" else "pamixer -d 2";
          on-click-middle = "crosspipe";
          menu = "on-click-right";
          menu-file = audioMenuFile;
          menu-actions = {
            pwvucontrol = "pwvucontrol";
          } // lib.genAttrs (map (n: "sink-${toString n}") (lib.range 0 (maxAudioSinks - 1)))
            (id: "my-audio-menu set ${lib.removePrefix "sink-" id}");
        };

        cava = {
          method = "pulse";
          input-delay = 4;
          bars = 8;
          framerate = 60;
          stereo = false;
          lower_cutoff_freq = 30;
          higher_cutoff_freq = 15000;
          noise_reduction = 0.75;
          sleep_timer = 1;
          bar_delimiter = 0;
          format_silent = "";
          hide_on_silence = true;
          format-icons = [
            "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█"
          ];
          actions = {
            on-click-right = "mode";
          };
          tooltip = false;
        }; 
        
        "custom/backup" = {
          exec = "my-backup";
          interval = 60;
          on-click = "my-backup";
          return-type = "json";
        };

        "custom/clock" = {
          exec = "my-date-formatter";
          interval = 30;
          tooltip = false;
        };
        
        network = {
          format = "{icon}";
          format-alt = "{ipaddr}/{cidr} {icon}";
          format-alt-click = "click-right";
          format-icons = {
            wifi = ["" "" ""];
            ethernet = [""];
            disconnected = [""];
          };
          on-click = "termite -e nmtui";
          tooltip = false;
        };
        
        backlight = {
          format = "{percent}% {icon}";
          format-icons = [ "" "" "" "" "" "" "" "" "" ];
          tooltip = false;
          reverse-scrolling = true;
        };
        
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "◉";
            deactivated = "○";
          };
          tooltip = false;
        };
        
        tray = {
          icon-size = 22;
          spacing = 10;
        };
      };
    };
    style = builtins.readFile ./style.css;
  };
}
