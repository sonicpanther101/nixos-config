{ host, inputs, lib, ... } : {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "bottom";
        position = "top";
        height = 30;

        modules-left = ["hyprland/workspaces"];
        modules-center = [ "clock" ];
        modules-right = [
          "mpris"
          (if (host == "desktop") then "cava" else "")
          "wireplumber"
          "tray"
          "idle_inhibitor"
          "backlight"
          (if (host == "laptop") then "battery" else "")
        ] ++ (lib.filter (x: x != "") [ ]);

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
            active = "";
            default = "";
          };
          persistent-workspaces = if (host == "desktop") then {
            "HDMI-A-1" = 5;
            "DP-1" = [ 11 12 13 14 15];
          } else {
            "*" = 5;
          };
        };

        mpris = {
          format = "{player_icon} {dynamic}";
          format-paused = "{status_icon} {dynamic}";
          player-icons = {
            default = "▐▐";
          };
          status-icons = {
            paused = "▶ ";
          };
          tooltip = false;
          on-scroll-up = "playerctl next";
          on-scroll-down = "playerctl previous";
        };

        wireplumber = {
          format = "{volume}% {icon}";
          format-muted = "0% ▁";
          on-click = "pamixer -t";
          format-icons = ["▃" "▅" "█"];
          on-scroll-up = "pamixer -i 2";
          on-scroll-down = "pamixer -d 2";
          on-click-middle = "helvum";
          on-click-right = "pwvucontrol";
        };

        cava = {
          cava_config = "${inputs.catppuccin-cava}/themes/mocha-transparent.cava";
          framerate = 60;
          bars = 8;
          lower_cutoff_freq = 30;
          higher_cutoff_freq = 15000;
          sleep_timer = 1;
          format_silent = "";
          method = "pipewire";
          stereo = false;
          bar_delimiter = 0;
          noise_reduction = 0.75;
          input_delay = 2;
          format-icons = ["▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
          actions = {
            on-click-right = "mode";
          };
        };
        
        clock = {
          format = "{:%a %d %b %I:%M%p}";
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
          format-icons = ["" ""];
          tooltip = false;
        };
        
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
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
        font-family:   Sans;
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
        color:      #89b4fa;
    }

    #workspaces button.visible {
        color:      #cdd6f4;
    }

    #workspaces button.focused {
        border-top: 3px solid #cdd6f4;
        border-bottom: 3px solid #89b4fa;
    }

    #workspaces button.urgent {
        color:      #f38ba8;
    }

    #mode, #battery, #cpu, #memory, #network, #pulseaudio, #idle_inhibitor, #backlight, #custom-storage, #custom-spotify, #custom-weather, #custom-mail {
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

    #tray {
      margin: 5px 5px 0;
    }
    '';
  };
}