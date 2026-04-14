{ host, ... } : {
  wayland.windowManager.hyprland.settings = {

    windowrule = [
      "match:title float_kitty, float on"
      "match:title float_kitty, center on"
      "match:title float_kitty, size 950 600"

      "match:class float_nemo, float on"
      "match:class float_nemo, center on"
      "match:class float_nemo, size 950 600"

      "match:class imv, float on"
      "match:class imv, center on"
      "match:class imv, size 1200 725"

      "match:class mpv, float on"
      "match:class mpv, center on"
      "match:class mpv, size 1200 725"

      "match:title OpenRGB, float on"
      "match:title Grayjay, tile on"

      "match:title Open Folder, float on"
      "match:title Open Folder, center on"
      "match:title Open Folder, size 950 600"

      "match:title Open File, float on"
      "match:title Open File, center on"
      "match:title Open File, size 950 600"

      "match:title Open Files, float on"
      "match:title Open Files, center on"
      "match:title Open Files, size 950 600"

      # Decreases opacity
      "match:class codium, opacity 0.9"
      "match:class vivaldi-stable, opacity 0.9"
      "match:title .*(YouTube|Last.fm|Movie).*, opacity 0.99"
      "match:class nemo, opacity 0.75"

      "match:title .*SableUI.*, float on"
      "match:title .*SableUI.*, pin on"              # Pin to all workspaces
      "match:title .*SableUI.*, no_border on"         # No border
      "match:title .*SableUI.*, no_blur on"           # No blur effect
      "match:title .*SableUI.*, no_shadow on"         # No shadow
      "match:title .*SableUI.*, no_anim on"           # No animations
      "match:title .*SableUI.*, no_initial_focus on"   # Don't focus on start
      "match:title .*SableUI.*, move 0 0"         # Position at top of screen with 40px height and full width
      
      "float, match:title .*Physics Simulation.*"

      # Stops screen sleep on idle
      "match:class mpv, idleinhibit focus"
      "match:class vlc, idleinhibit focus"
      "match:title .*YouTube.*, idleinhibit focus"
      "match:title .*Syncthing.*, idleinhibit focus"
      "match:title .*LEARN.*, idleinhibit focus"
      "match:title .*Tutorial.*, idleinhibit focus"
      "match:title .*Lab Report.*, idleinhibit focus"
      "match:title .*homework.*, idleinhibit focus"
      "match:title Grayjay, idleinhibit focus"
      "match:title cava, idleinhibit focus"
      
      /*

      "float,match:class imv, "
      "center,match:class imv, "
      "size 1200 725,match:class imv, "

      "float,match:class mpv, "
      "center,match:class mpv, "
      "size 1200 725,match:class mpv, "

      "float,match:title Open Folder"
      "center,match:title Open Folder"
      "size 950 600,match:title Open Folder"

      "float,match:title Open File"
      "center,match:title Open File"
      "size 950 600,match:title Open File"

      # Floating
      "float,match:title OpenRGB"
      "float,match:class pavucontrol, "
      "float,match:class SoundWireServer, "
      "float,match:class .sameboy-wrapped, "
      "float,match:class file_progress, "
      "float,match:class confirm, "
      "float,match:class dialog, "
      "float,match:class download, "
      "float,match:class notification, "
      "float,match:class error, "
      "float,match:class confirmreset, "
      "float,match:title Open File"
      "float,match:title branchdialog"
      "float,match:title Confirm to replace files"
      "float,match:title File Operation Progress"

      # Force tiling
      "tile,match:title .*[foobar2000].*"
      # Grayjay - since initialTitle is EMPTY, we need a workaround
      # Try matching on xwayland:1 with NO title/class filters
      "tile,xwayland:1,floating:1" # This forces any xwayland floating window to tile

      # For use with future astal/sableui projects
      # "float,match:title gemini-ui"
      # "move 100%-0%,match:title gemini-ui"
      # "size 500 750,match:title gemini-ui"
      # "pin,match:title gemini-ui"

      # Decreases opacity (dubious)
      "opacity 0.9,match:class codium, "
      "opacity 0.9,match:class vivaldi-stable, "
      "opacity 0.99,match:title .*YouTube.*"
      "opacity 0.75,match:class nemo, "

      # Stops screen sleep on idle
      "idleinhibit focus,match:class mpv, "
      "idleinhibit focus,match:class vlc, "
      "idleinhibit focus,match:class steam_proton, "
      "idleinhibit focus,match:title .*YouTube.*"
      "idleinhibit focus,match:title Grayjay"
      */
    ]; 

    # Old window rules

    # windowrule
    /* windowrule = [
      
      "float,audacious"
      "workspace 8 silent, audacious"
      "tile, neovide"
      "float,udiskie"
      "float,match:title Transmission"
      "float,match:title Volume Control"
      "size 700 450,match:title Volume Control"
      "move 40 55%,match:title Volume Control"
      
    ]; */

    # windowrulev2
    /* windowrulev2 = [
      "float, match:title Picture-in-Picture"
      "opacity 1.0 override 1.0 override, match:title Picture-in-Picture"
      "pin, match:title Picture-in-Picture"
      "opacity 1.0 override 1.0 override, match:title .*imv.*"
      "opacity 1.0 override 1.0 override, match:title .*mpv.*"
      "opacity 1.0 override 1.0 override, class:(Aseprite)"
      "opacity 1.0 override 1.0 override, class:(Unity)"
      "idleinhibit focus, match:class mpv, "
      "idleinhibit fullscreen, match:class firefox, "
    ]; */

    layerrule = [
      "above_lock 2, match:namespace wvkbd"
    ];
 };
}