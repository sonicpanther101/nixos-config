{ ... } : {
  wayland.windowManager.hyprland.settings = {

    windowrule = [
      "match:class Matplotlib, float on"
      "match:class Matplotlib, center on"
      "match:class Matplotlib, size 950 600"

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

      "match:title Open Folder, float on"
      "match:title Open Folder, center on"
      "match:title Open Folder, size 950 600"

      "match:title Open File, float on"
      "match:title Open File, center on"
      "match:title Open File, size 950 600"

      "match:title Open file, float on"
      "match:title Open file, center on"
      "match:title Open file, size 950 600"

      "match:title Open Files, float on"
      "match:title Open Files, center on"
      "match:title Open Files, size 950 600"

      "match:title Save File, float on"
      "match:title Save File, center on"
      "match:title Save File, size 950 600"

      "match:title Active connection found, float on"
      "match:title Active connection found, center on"

      "match:title Edit Item, float on"
      "match:title Edit Item, center on"

      # Decreases opacity
      "match:class codium, opacity 0.9"
      "match:class foobar2000.exe, opacity 0.9"
      "match:class vivaldi-stable, opacity 0.9"
      "match:title .*(Last.fm|Movie).*, opacity 0.99"
      "match:class nemo, opacity 0.75"

      "match:title .*SableUI.*, float on"
      "match:title .*SableUI.*, pin on"              # Pin to all workspaces
      "match:title .*SableUI.*, border_size 0"       # No border
      "match:title .*SableUI.*, no_blur on"          # No blur effect
      "match:title .*SableUI.*, no_shadow on"        # No shadow
      "match:title .*SableUI.*, no_anim on"          # No animations
      "match:title .*SableUI.*, no_initial_focus on" # Don't focus on start
      "match:title .*SableUI.*, move 0 0"            # Position at top of screen with 40px height and full width
      
      "match:title .*Physics Simulation.*, float on"
      
      # Stops screen sleep on idle
      "match:class mpv, idle_inhibit focus"
      "match:class vlc, idle_inhibit focus"
      "match:title .*Syncthing.*, idle_inhibit focus"
      "match:title .*LEARN.*, idle_inhibit focus"
      "match:title .*Tutorial.*, idle_inhibit focus"
      "match:title .*Lab Report.*, idle_inhibit focus"
      "match:title .*homework.*, idle_inhibit focus"
      "match:title cava, idle_inhibit focus"
    ]; 

    # hyprctl layers to see namespace
    # 2 means interactible, 1 means visible
    layerrule = [
      "above_lock 2, match:namespace wvkbd"
      "above_lock 2, match:namespace waybar"
      "above_lock 2, match:namespace sunshine"
    ];
 };
}