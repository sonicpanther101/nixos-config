{ ... }:
let
  mkFloatRules = { match, type, extra ? [] , size ? null }:
    let
      base = [
        "match:${type} ${match}, float on"
        "match:${type} ${match}, center on"
      ];
      sizeRule =
        if size != null then [ "match:${type} ${match}, size ${toString (builtins.elemAt size 0)} ${toString (builtins.elemAt size 1)}" ]
        else [];
      # `extra` is a list of bare rule values (e.g. "workspace r+0"); turn
      # each into a full "match:type match, value" line like the others.
      extraRules = map (v: "match:${type} ${match}, ${v}") extra;
    in base ++ sizeRule ++ extraRules;

  floatByClass = [
    { match = "Matplotlib"; size = [950 600]; type = "class"; }
    { match = "float_nemo"; size = [950 600]; type = "class"; }
    { match = "imv"; size = [1200 725]; type = "class"; }
    { match = "mpv"; size = [1200 725]; type = "class"; }
  ];

  # "workspace r+0" pins a newly-opened window to whatever workspace is
  # currently active on the monitor it opens on ("relative +0" = no move).
  # These are all transient system dialogs/popups spawned by a background
  # process (e.g. the xdg-desktop-portal file picker triggered by "add
  # file"), so they can appear on whatever workspace that background
  # process happens to "live" on -- including ones outside the range your
  # keybinds normally reach -- instead of wherever you're actually looking.
  # This rule makes them always land in front of you automatically, so you
  # shouldn't need the manual SUPER ALT G "grab rogue windows" rescue for
  # these specific dialogs any more.
  autoWorkspaceRule = [ "workspace r+0" ];

  floatByTitle = [
    { match = "float_kitty"; size = [950 600]; type = "title"; }
    { match = "Open Folder"; size = [950 600]; type = "title"; extra = autoWorkspaceRule; }
    { match = "Open File"; size = [950 600]; type = "title"; extra = autoWorkspaceRule; }
    { match = "Open file"; size = [950 600]; type = "title"; extra = autoWorkspaceRule; }
    { match = "Open Files"; size = [950 600]; type = "title"; extra = autoWorkspaceRule; }
    { match = "Save File"; size = [950 600]; type = "title"; extra = autoWorkspaceRule; }
    { match = ".* Reminders"; size = [600 200]; type = "title"; extra = autoWorkspaceRule; }
    { match = "Extract"; size = [850 200]; type = "title"; extra = autoWorkspaceRule; }
    { match = "Active connection found"; type = "title"; extra = autoWorkspaceRule; }
    { match = "Edit Item"; type = "title"; extra = autoWorkspaceRule; }
    { match = "Calendar Reminders"; type = "title"; extra = autoWorkspaceRule; }
    { match = "OpenRGB"; type = "title"; }
    { match = ".*Physics Simulation.*"; type = "title"; }
    { match = "Pipewire Volume Control"; type = "title"; extra = autoWorkspaceRule; }
    { match = ".*Properties.*"; type = "title"; extra = autoWorkspaceRule; }
  ];

  floatRules =
    builtins.concatLists (
      (map (r: mkFloatRules r) floatByClass) ++
      (map (r: mkFloatRules r) floatByTitle)
    );

in {
  wayland.windowManager.hyprland.settings = {

    windowrule = floatRules ++ [
      # Decreases opacity
      "match:class codium, opacity 0.9"
      "match:class foobar2000.exe, opacity 0.9"
      "match:class vivaldi-stable, opacity 0.9"
      "match:title .*(Last.fm|Movie).*, opacity 1"
      "match:class nemo, opacity 0.75"

      "match:title .*SableUI.*, float on"
      "match:title .*SableUI.*, pin on"              # Pin to all workspaces
      "match:title .*SableUI.*, border_size 0"       # No border
      "match:title .*SableUI.*, no_blur on"          # No blur effect
      "match:title .*SableUI.*, no_shadow on"        # No shadow
      "match:title .*SableUI.*, no_anim on"          # No animations
      "match:title .*SableUI.*, no_initial_focus on" # Don't focus on start
      "match:title .*SableUI.*, move 0 0"            # Position at top of screen with 40px height and full width
      
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

