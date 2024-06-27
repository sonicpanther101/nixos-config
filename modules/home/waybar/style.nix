{ ... }:
let custom = {
    font = "JetBrainsMono Nerd Font";
    font_size = "15px";
    font_weight = "bold";
    text_color = "#cdd6f4";
    secondary_accent= "89b4fa";
    tertiary_accent = "f5f5f5";
    background = "11111B";
    opacity = "0.98";
};
in 
{
  programs.waybar.style = ''

    * {
        border: none;
        border-radius: 0px;
        padding: 0;
        margin: 0;
        min-height: 0px;
        font-family: ${custom.font};
        font-weight: ${custom.font_weight};
        opacity: ${custom.opacity};
    }

    window#waybar {
        background: none;
    }

    #workspaces {
        font-size: 18px;
        background-color: rgba(108, 112, 134, 0.3);
        border-radius: 50px;
    }
    #workspaces button {
        color: ${custom.text_color};
        padding-left:  6px;
        padding-right: 9px;
        border-radius: 50px;
    }
    #workspaces button.empty {
        color: #6c7086;
    }
    #workspaces button.active {
        color: #b4befe;
        background-color: rgba(180,190,254,0.3);
    }

    #custom-left {
        background-color: rgba(108, 112, 134, 0.3);
        border-bottom-left-radius: 50px;
        border-top-left-radius: 50px;
    }

    #custom-right {
        background-color: rgba(108, 112, 134, 0.3);
        border-top-right-radius: 50px;
        border-bottom-right-radius: 50px;
    }

    #tray, #pulseaudio, #network, #cpu, #memory, #disk, #clock, #battery, #custom-launcher {
        font-size: ${custom.font_size};
        color: ${custom.text_color};
        background-color: rgba(108, 112, 134, 0.3);
    }

    #cpu {
        padding-left: 15px;
        padding-right: 9px;
    }
    #memory {
        padding-left: 9px;
        padding-right: 9px;
    }
    #disk {
        padding-left: 9px;
        padding-right: 15px;
    }

    #tray {
        padding: 0 20px;
    }

    #pulseaudio {
        padding-left: 9px;
        padding-right: 9px;
    }
    #battery {
        padding-left: 9px;
        padding-right: 9px;
    }
    #network {
        padding-left: 9px;
        padding-right: 15px;
    }
    
    #clock {
        padding-left: 9px;
        padding-right: 15px;
        margin-right: 30px;
        border-bottom-left-radius: 15px;
        border-bottom-right-radius: 15px;
    }

    #custom-launcher {
        font-size: 20px;
        font-weight: ${custom.font_weight};
        padding-left: 5px;
        padding-right: 15px;
        margin-right: 25px;
        border-bottom-right-radius: 15px;
    }

    #custom-media {
        background-color: rgba(108, 112, 134, 0.3);
    }
  '';
}
