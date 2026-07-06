{ isHighPower, isLaptop, lib, pkgs-unstable, ... } : {
  programs.waybar = {
    enable = true;
    package = pkgs-unstable.waybar;
    settings = {
      mainBar = {
        layer = "bottom";
        position = "top";
        height = 30;

        modules-left = [ "custom/menu" "hyprland/workspaces" ];
        modules-center = [ "custom/pomodoro" "custom/clock" ];
        modules-right = [
          "custom/mpris"
          "image#album-art"
        ] ++ lib.optionals isHighPower [
          "cava"
        ] ++ [
          "wireplumber"
          "tray"
          "backlight"
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
          # persistent-workspaces = if (host != host) then {
          persistent-workspaces = {
            "HDMI-A-1" = [ 11 12 13 14 15 ];
            "DP-1" = [ 1 2 3 4 5 ];
            "eDP-1" = [ 21 22 23 24 25 ];
          };
          active-only = true;
          on-scroll-up   = "hyprctl dispatch split-cycleworkspaces +1";
          on-scroll-down = "hyprctl dispatch split-cycleworkspaces -1";
        };

        "custom/keyboard" = {
          format = "⌨";
          tooltip = false;
          on-click = "my-toggle-keyboard";
        };

        "image#album-art" = {
          exec = "playerctl metadata mpris:artUrl | sed 's|^file://||'";
          interval = 10;
          on-click = "playerctl play-pause";
          on-scroll-up = "playerctl next";
          on-scroll-down = "playerctl previous";
          size = 24;
          tooltip = false;
        };

        "custom/pomodoro" = {
          exec = ''
            if [ -f /tmp/pomodoro-waybar ] &&
              [ $(( $(date +%s) - $(stat -c %Y /tmp/pomodoro-waybar) )) -lt 3 ]
            then
              tail -f /tmp/pomodoro-waybar
            fi
          '';
          restart-interval = 1;
          return-type = "plain";
          tooltip = false;
        };

        "custom/mpris" = {
          exec = "my-mpris-waybar";
          restart-interval = 1;
          tooltip = false;
          on-click = "playerctl play-pause";
          on-scroll-up = "playerctl next";
          on-scroll-down = "playerctl previous";
        };

        mpris = {
          format = "{player_icon} {dynamic}";
          format-paused = "{status_icon} {dynamic}";
          player-icons = {
            default = "⏸";
          };
          status-icons = {
            paused = "▶";
          };
          tooltip = false;
          on-scroll-up = "playerctl next";
          on-scroll-down = "playerctl previous";
          max-length = 45;
        };

        "custom/menu" = {
          format = "";
          tooltip = "Power & Screen Rotation";
          menu = "on-click";
          menu-file = "${./menu.xml}";
          menu-actions = {
            lock = "pidof hyprlock || hyprlock";
            sleep = "my-sleep";
            sleep-1 = "my-sleep";
            poweroff = "hyprshutdown -t 'Shutting down...' --post-cmd 'my-shutdown'";
            reboot = "hyprshutdown -t 'Restarting...' --post-cmd 'reboot'";
            
            wallpaper = "walker -m menus:wallpapers";
            keybinds = "walker -m menus:keybinds";
            aliases = "walker -m menus:aliases";

            upright = "hyprctl keyword monitor \"eDP-1,preferred,auto,1.9,transform,0\"";
            left = "hyprctl keyword monitor \"eDP-1,preferred,auto,1.9,transform,1\"";
            upside = "hyprctl keyword monitor \"eDP-1,preferred,auto,1.9,transform,2\"";
            right = "hyprctl keyword monitor \"eDP-1,preferred,auto,1.9,transform,3\"";

            cw = "bash -c 'current=$(hyprctl monitors | grep -A2 \"eDP-1\" | grep transform | awk \"{print \\$2}\"); next=$(( (current + 1) % 4 )); hyprctl keyword monitor \"eDP-1,preferred,auto,1.9,transform,$next\"'";
            ccw = "bash -c 'current=$(hyprctl monitors | grep -A2 \"eDP-1\" | grep transform | awk \"{print \\$2}\"); next=$(( (current + 3) % 4 )); hyprctl keyword monitor \"eDP-1,preferred,auto,1.9,transform,$next\"'";
            flip = "bash -c 'current=$(hyprctl monitors | grep -A2 \"eDP-1\" | grep transform | awk \"{print \\$2}\"); next=$(( (current + 2) % 4 )); hyprctl keyword monitor \"eDP-1,preferred,auto,1.9,transform,$next\"'";
          };
        };

        wireplumber = {
          format = "{volume}% {icon}";
          format-muted = "0% 󰝟";
          on-click = "pamixer -t";
          format-icons = ["󰕿" "󰖀" "󰕾"];
          on-scroll-up = "pamixer -i 2";
          on-scroll-down = "pamixer -d 2";
          on-click-middle = "crosspipe";
          on-click-right = "pwvucontrol";
        };

        cava = {
          method = "pipewire";
          bars = 8;
          framerate = 60;
          stereo = false;
          lower_cutoff_freq = 30;
          higher_cutoff_freq = 15000;
          noise_reduction = 0.75;
          sleep_timer = 1;
          bar_delimiter = 0;
          format_silent = "";
          format-icons = [
            "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█"
          ];
          actions = {
            on-click-right = "mode";
          };
          tooltip = false;
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
    style = ''
    * {
        border:        none;
        border-radius: 0;
        font-family:   "JetBrainsMono Nerd Font", "Symbols Nerd Font", Sans;
        font-size:     15px;
        box-shadow:    none;
        text-shadow:   none;
        transition-duration: 0s;
    }

    window {
        color:      #cdd6f4;
        background: #1e1e2e;
    }

    window#waybar.solo {
        color:      #cdd6f4;
        background: rgba(35, 31, 32, 0.85);
    }

    #workspaces {
        margin: 0 5px;
    }

    #workspaces button {
        padding:    0 5px;
        color:      #cdd6f4;
    }

    #workspaces button.empty {
        color:      #45475a;
    }

    #workspaces button.visible {
        color:      #89b4fa;
    }

    #workspaces button.urgent {
        color:      #f38ba8;
    }

    #mode, #battery, #cpu, #memory, #network, #pulseaudio, #custom-storage, #custom-weather, #custom-mail {
        margin:     0px 6px 0px 10px;
        min-width:  25px;
    }

    #clock {
        margin:     0px 16px 0px 10px;
        min-width:  140px;
    }

    #battery.warning {
      color:       #f9e2af;
    }

    #battery.critical {
        color:      #f38ba8;
    }

    #battery.charging {
        color:      #a6e3a1;
    }

    #battery.charged {
        color:      #a6e3a1;
    }

    #custom-storage.warning {
        color:      #f9e2af;
    }

    #custom-storage.critical {
        color:      #f38ba8;
    }

    #idle_inhibitor {
        margin-right: 3px;
    }

    #image {
        margin: 0px 7px 0px 5px;
    }

    #image.empty {
        margin: 0px;
    }

    #custom-keyboard {
        margin: 3px 2px 0px 3px;
        min-width: 25px;
    }

    #custom-pomodoro {
        min-width: 90px;
        margin: 0 10px;
    }

    #custom-mpris {
        margin: 3px 4px 0 0;
    }
    
    #custom-menu {
        padding: 0 3px 0 7px;
    }

    menu {
        border-radius: 15px;
        background: #1e1e2e;
        color: #cdd6f4;
    }
    menuitem {
        border-radius: 15px;
    }

    #tray {
      margin: 5px 5px 0;
    }
    '';
  };
}