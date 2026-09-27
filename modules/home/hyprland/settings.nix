{ host, lib, isLaptop, ... } :
let
  # Monitor descriptions extracted directly from hyprctl
  dp1Desc = "desc:ASUSTek COMPUTER INC VG27AQ1A S9LMQS099860";
  hdmi1Desc = "desc:AOC 27B30H 1AQQ7HA015555";

  # -------------------------------------------------------------------
  # Hyprland 0.55+ moved to a Lua config. home-manager's `settings`
  # option does NOT support this correctly for configType = "lua":
  # it turns every top-level key into a bare `hl.<key>(...)` call
  # (nix-community/home-manager#9468, #9341), but the real Lua API only
  # exposes a handful of dedicated functions (hl.monitor, hl.device,
  # hl.animation, hl.curve, hl.workspace_rule, hl.bind, ...) - most
  # sections (general, decoration, input, misc, dwindle, master,
  # cursor, debug, binds, xwayland) actually belong inside a single
  # hl.config({ ... }) call instead. `animations` isn't a hl.config
  # section at all - it's `hl.animation()` per animation + `hl.curve()`
  # per bezier. This is why Hyprland crashed with:
  #   attempt to call a nil value (field 'animations')
  # (it tried to call `hl.animations(...)`, which doesn't exist).
  #
  # So instead of using `settings`, we build the Lua text ourselves
  # here and hand it to `extraConfig`, which IS emitted correctly.
  # -------------------------------------------------------------------

  toLua = lib.generators.toLua { };

  # Everything that maps cleanly onto hl.config({ ... })
  configTable = {
    binds = {
      scroll_event_delay = 0;
    };

    input = {
      kb_layout = "us";
      numlock_by_default = false;
      repeat_delay = 250;
      repeat_rate = 50;

      touchpad = {
        natural_scroll = true;
        disable_while_typing = true;
        clickfinger_behavior = true;
        scroll_factor = 0.5;
      };

      follow_mouse = 1;
      accel_profile = "flat";
      sensitivity = 0.6;
    };

    cursor.no_warps = true;
    debug.disable_logs = false;

    general = {
      layout = "dwindle";
      gaps_in = 3;
      gaps_out = 6;
      gaps_workspaces = 10;
      border_size = 2;
      "col.active_border" = "rgb(89b4fa)";
    };

    misc = {
      allow_session_lock_restore = true;
      disable_autoreload = true;
      disable_hyprland_logo = true;
      always_follow_on_dnd = true;
      layers_hog_keyboard_focus = true;
      animate_manual_resizes = false;
      enable_swallow = true;
      focus_on_activate = true;
    };

    dwindle = {
      force_split = 0;
      special_scale_factor = 1.0;
      split_width_multiplier = 1.0;
      use_active_for_splits = true;
      preserve_split = true;
      smart_resizing = false;
    };

    master = {
      special_scale_factor = 1;
    };

    decoration = {
      rounding = 3;
      active_opacity = 1.0;
      inactive_opacity = 0.98;
      fullscreen_opacity = 1.0;

      blur = {
        enabled = true;
        size = 1;
        special = false;
        passes = 1;
        brightness = 1;
        contrast = 1;
        ignore_opacity = true;
        noise = 0;
        new_optimizations = true;
        xray = false;
      };

      dim_inactive = true;
      dim_strength = 0.02;
      dim_special = 0;
    };

    xwayland.force_zero_scaling = true;
  };

  # device -> one hl.device({ ... }) call per entry
  devices = lib.optionals (host == "laptop-2") [
    {
      name = "wacom-hid-4915-pen";
      output = "eDP-1";
    }
  ];

  # monitor -> one hl.monitor({ ... }) call per entry
  # ("" for output is the Lua-config equivalent of hyprlang's blank
  # wildcard name, e.g. `monitor = ,preferred,auto,2`)
  monitors =
    if host == "desktop" then [
      {
        output = dp1Desc;
        mode = "2560x1440@170";
        position = "0x0";
        scale = 1.3333;
      }
      {
        output = hdmi1Desc;
        mode = "1920x1080@100";
        position = "1921x0";
        scale = 1;
      }
    ] else if isLaptop then [
      {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = 2;
      }
    ] else [
      {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = 1;
      }
    ];

  # workspace-to-monitor assignments -> one hl.workspace_rule({ ... }) per entry
  workspaceRules = lib.optionals (host == "desktop") (
    (map (i: { workspace = toString i; monitor = dp1Desc; }) (lib.range 1 10)) ++
    (map (i: { workspace = toString i; monitor = hdmi1Desc; }) (lib.range 11 20))
  );

  # ---- Animations ----
  # Kept in the original hyprlang comma-separated form here so the
  # actual values only live in one place, then parsed into the
  # structured tables hl.curve()/hl.animation() need.
  trim = lib.strings.trim;
  splitTrim = s: map trim (lib.splitString "," s);
  num = s: builtins.fromJSON (trim s);

  bezierRaw = [
    "md3_decel, 0.05, 0.7, 0.1, 1"
    "md3_accel, 0.3, 0, 0.8, 0.15"
    "overshot, 0.05, 0.9, 0.1, 1.1"
    "crazyshot, 0.1, 1.5, 0.76, 0.92"
    "hyprnostretch, 0.05, 0.9, 0.1, 1.0"
    "fluent_decel, 0.1, 1, 0, 1"
    "easeInOutCirc, 0.85, 0, 0.15, 1"
    "easeOutCirc, 0, 0.55, 0.45, 1"
    "easeOutExpo, 0.16, 1, 0.3, 1"
  ];

  animationRaw = [
    "windows, 1, 2, md3_decel, popin 60%"
    "border, 1, 10, default"
    "fade, 1, 2.5, md3_decel"
    "workspaces, 1, 3, fluent_decel, slide"
    "specialWorkspace, 1, 3, md3_decel, slidevert"
  ];

  curves = map
    (raw:
      let p = splitTrim raw;
      in {
        name = builtins.elemAt p 0;
        points = [
          [ (num (builtins.elemAt p 1)) (num (builtins.elemAt p 2)) ]
          [ (num (builtins.elemAt p 3)) (num (builtins.elemAt p 4)) ]
        ];
      })
    bezierRaw;

  animationLeaves = map
    (raw:
      let
        p = splitTrim raw;
        n = builtins.length p;
      in
      {
        leaf = builtins.elemAt p 0;
        enabled = (num (builtins.elemAt p 1)) == 1;
        speed = num (builtins.elemAt p 2);
        bezier = builtins.elemAt p 3;
      } // lib.optionalAttrs (n >= 5) { style = builtins.elemAt p 4; })
    animationRaw;

  luaLines =
    [ "hl.config(${toLua configTable})" ]
    ++ map (d: "hl.device(${toLua d})") devices
    ++ map (m: "hl.monitor(${toLua m})") monitors
    ++ map (w: "hl.workspace_rule(${toLua w})") workspaceRules
    ++ map (c: ''hl.curve(${toLua c.name}, { type = "bezier", points = ${toLua c.points} })'') curves
    ++ map (a: "hl.animation(${toLua a})") animationLeaves;
in
{
  wayland.windowManager.hyprland.extraConfig = lib.concatStringsSep "\n\n" luaLines + "\n";
}
