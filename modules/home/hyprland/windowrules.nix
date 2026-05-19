{ ... } : {
wayland.windowManager.hyprland.extraConfig = 
let
  windowrule = ct: match: action: ''hl.window_rule({ match = { ${ct} = "${match}" }, ${action}})'';
  lines = builtins.concatStringsSep "\n";
in
  lines [
    (windowrule "class" "Matplotlib" "float = true")
    (windowrule "class" "Matplotlib" "center = true")
    (windowrule "class" "Matplotlib" "size = {\"(monitor_w*0.5)\", \"(monitor_h*0.5)\"}")

    (windowrule "title" "float_kitty" "float = true")
    (windowrule "title" "float_kitty" "center = true")
    (windowrule "title" "float_kitty" "size = {\"(monitor_w*0.5)\", \"(monitor_h*0.5)\"}")

    (windowrule "class" "float_nemo" "float = true")
    (windowrule "class" "float_nemo" "center = true")
    (windowrule "class" "float_nemo" "size = {\"(monitor_w*0.5)\", \"(monitor_h*0.5)\"}")

    (windowrule "class" "imv" "float = true")
    (windowrule "class" "imv" "center = true")
    (windowrule "class" "imv" "size = {\"(monitor_w*0.5)\", \"(monitor_h*0.5)\"}")

    (windowrule "class" "mpv" "float = true")
    (windowrule "class" "mpv" "center = true")
    (windowrule "class" "mpv" "size = {\"(monitor_w*0.5)\", \"(monitor_h*0.5)\"}")

    (windowrule "title" "OpenRGB" "float = true")
    (windowrule "title" "Grayjay" "tile = true")

    (windowrule "title" "Open Folder" "float = true")
    (windowrule "title" "Open Folder" "center = true")
    (windowrule "title" "Open Folder" "size = {\"(monitor_w*0.5)\", \"(monitor_h*0.5)\"}")

    (windowrule "title" "Open File" "float = true")
    (windowrule "title" "Open File" "center = true")
    (windowrule "title" "Open File" "size = {\"(monitor_w*0.5)\", \"(monitor_h*0.5)\"}")

    (windowrule "title" "Open file" "float = true")
    (windowrule "title" "Open file" "center = true")
    (windowrule "title" "Open file" "size = {\"(monitor_w*0.5)\", \"(monitor_h*0.5)\"}")

    (windowrule "title" "Open Files" "float = true")
    (windowrule "title" "Open Files" "center = true")
    (windowrule "title" "Open Files" "size = {\"(monitor_w*0.5)\", \"(monitor_h*0.5)\"}")

    (windowrule "title" "Save File" "float = true")
    (windowrule "title" "Save File" "center = true")
    (windowrule "title" "Save File" "size = {\"(monitor_w*0.5)\", \"(monitor_h*0.5)\"}")

    # Decreases opacity
    (windowrule "class" "codium" "opacity = 0.9")
    (windowrule "class" "vivaldi-stable" "opacity = 0.9")
    (windowrule "title" ".*(YouTube|Last.fm|Movie).*" "opacity = 0.99")
    (windowrule "class" "nemo" "opacity = 0.75")

    (windowrule "title" ".*SableUI.*" "float = true")
    (windowrule "title" ".*SableUI.*" "pin = true")              # Pin to all workspaces
    (windowrule "title" ".*SableUI.*" "border_size = 0")         # No border
    (windowrule "title" ".*SableUI.*" "no_blur = true")          # No blur effect
    (windowrule "title" ".*SableUI.*" "no_shadow = true")        # No shadow
    (windowrule "title" ".*SableUI.*" "no_anim = true")          # No animations
    (windowrule "title" ".*SableUI.*" "no_initial_focus = true") # Don't focus on start
    (windowrule "title" ".*SableUI.*" "move = {0, 0}")           # Position at top of screen with 40px height and full width
    
    (windowrule "title" ".*Physics Simulation.*" "float = true")
    
    # Stops screen sleep on idle
    (windowrule "class" "mpv" "idle_inhibit = focus")
    (windowrule "class" "vlc" "idle_inhibit = focus")
    (windowrule "title" ".*YouTube.*" "idle_inhibit = focus")
    (windowrule "title" ".*Syncthing.*" "idle_inhibit = focus")
    (windowrule "title" ".*LEARN.*" "idle_inhibit = focus")
    (windowrule "title" ".*Tutorial.*" "idle_inhibit = focus")
    (windowrule "title" ".*Lab Report.*" "idle_inhibit = focus")
    (windowrule "title" ".*homework.*" "idle_inhibit = focus")
    (windowrule "title" "Grayjay" "idle_inhibit = focus")
    (windowrule "title" "cava" "idle_inhibit = focus")

    # hyprctl layers to see namespace
    # 2 means interactible, 1 means visible
    ''hl.layer_rule({ match = {namespace = "wvkbd" }, above_lock = 2 })''
    ''hl.layer_rule({ match = {namespace = "waybar" }, above_lock = 2 })''
  ];
}