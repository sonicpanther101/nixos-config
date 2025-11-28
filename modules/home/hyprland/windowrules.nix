{ host, ... } : {
  wayland.windowManager.hyprland.settings = {

    windowrule = [
      "float,title:^(float_kitty)$"
      "center,title:^(float_kitty)$"
      "size 950 600,title:^(float_kitty)$"

      "float,class:^(imv)$"
      "center,class:^(imv)$"
      "size 1200 725,class:^(imv)$"

      "float,class:^(mpv)$"
      "center,class:^(mpv)$"
      "size 1200 725,class:^(mpv)$"

      # Force tiling
      "tile,title:^(Grayjay)$"

      "float,title:^(Open Folder)$"
      "center,title:^(Open Folder)$"
      "size 950 600,title:^(Open Folder)$"

      "float,title:^(Open File)$"
      "center,title:^(Open File)$"
      "size 950 600,title:^(Open File)$"
    ];

    windowrulev2 = [

      # Floating
      "float,title:^(OpenRGB)$"
      "float,class:^(pavucontrol)$"
      "float,class:^(SoundWireServer)$"
      "float,class:^(.sameboy-wrapped)$"
      "float,class:^(file_progress)$"
      "float,class:^(confirm)$"
      "float,class:^(dialog)$"
      "float,class:^(download)$"
      "float,class:^(notification)$"
      "float,class:^(error)$"
      "float,class:^(confirmreset)$"
      "float,title:^(Open File)$"
      "float,title:^(branchdialog)$"
      "float,title:^(Confirm to replace files)$"
      "float,title:^(File Operation Progress)$"

      # Force tiling
      "tile,title:^(.*[foobar2000].*)$"

      # For use with future astal/sableui projects
      /* "float,title:^(gemini-ui)$"
      "move 100%-0%,title:^(gemini-ui)$"
      "size 500 750,title:^(gemini-ui)$"
      "pin,title:^(gemini-ui)$" */

      # Decreases opacity (dubious)
      "opacity 0.9,class:^(codium)$"
      "opacity 0.9,class:^(vivaldi)$"
      "opacity 0.99,title:^(.*YouTube.*)$"
      "opacity 0.75,class:^(nemo)$"

      # Stops screen sleep on idle
      "idleinhibit focus,class:^(mpv)$"
      "idleinhibit focus,class:^(vlc)$"
      "idleinhibit focus,class:^(steam_proton)$"
      "idleinhibit focus,title:^(.*YouTube.*)$"
      "idleinhibit focus,title:^(Grayjay)$"
    ];

    # Old window rules

    # windowrule
    /* windowrule = [
      
      "float,audacious"
      "workspace 8 silent, audacious"
      "tile, neovide"
      "float,udiskie"
      "float,title:^(Transmission)$"
      "float,title:^(Volume Control)$"
      "size 700 450,title:^(Volume Control)$"
      "move 40 55%,title:^(Volume Control)$"
      
    ]; */

    # windowrulev2
    /* windowrulev2 = [
      "float, title:^(Picture-in-Picture)$"
      "opacity 1.0 override 1.0 override, title:^(Picture-in-Picture)$"
      "pin, title:^(Picture-in-Picture)$"
      "opacity 1.0 override 1.0 override, title:^(.*imv.*)$"
      "opacity 1.0 override 1.0 override, title:^(.*mpv.*)$"
      "opacity 1.0 override 1.0 override, class:(Aseprite)"
      "opacity 1.0 override 1.0 override, class:(Unity)"
      "idleinhibit focus, class:^(mpv)$"
      "idleinhibit fullscreen, class:^(firefox)$"
    ]; */
  };
}