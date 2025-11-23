{ host, inputs, ... } : {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "bottom";
        position = "top";
        height = 30;

        modules-left = ["hyprland/workspaces"];
        modules-center = [ "clock" ];
        modules-right = [ "mpris" "cava" "wireplumber" "tray" ] ++ (if (host == "laptop") then [
          "battery"
        ] else []);

        "hyprland/workspaces" = {
          format = "<sub>{icon}</sub>";
          format-icons = {
            active = "";
            default = "";
          };
          persistent-workspaces = {
            "HDMI-A-1" = 5;
            "DP-1" = [ 11 12 13 14 15];
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
          lower_cutoff_freq = 20;
          higher_cutoff_freq = 20000;
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
          format = "{icon}";
          format-alt = "{percent}% {icon}";
          format-alt-click = "click-right";
          format-icons = ["" ""];
          on-scroll-down = "light -A 1";
          on-scroll-up = "light -U 1";
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
        color:      rgba(217, 216, 216, 1);
        background: rgba(35, 31, 32, 0.00);
    }

    window#waybar.solo {
        color:      rgba(217, 216, 216, 1);
        background: rgba(35, 31, 32, 0.85);
    }

    #workspaces {
        margin: 0 5px;
    }

    #workspaces button {
        padding:    0 5px;
        color:      rgba(217, 216, 216, 0.4);
    }

    #workspaces button.visible {
        color:      rgba(217, 216, 216, 1);
    }

    #workspaces button.focused {
        border-top: 3px solid rgba(217, 216, 216, 1);
        border-bottom: 3px solid rgba(217, 216, 216, 0);
    }

    #workspaces button.urgent {
        color:      rgba(238, 46, 36, 1);
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
      color:       rgba(255, 210, 4, 1);
    }

    #battery.critical {
        color:      rgba(238, 46, 36, 1);
    }

    #battery.charging {
        color:      rgba(217, 216, 216, 1);
    }

    #custom-storage.warning {
        color:      rgba(255, 210, 4, 1);
    }

    #custom-storage.critical {
        color:      rgba(238, 46, 36, 1);
    }

    #tray {
      margin: 5px 10px 0;
    }
    '';
  };
}