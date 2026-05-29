#!/usr/bin/env python3
"""show-keybinds — live keybind browser, auto-parsed from hyprctl binds.

Displayed in a floating kitty window (title: float_keybinds) with fzf.
Selecting an entry executes the bind via hyprctl dispatch.
"""

import json, re, subprocess, sys
from collections import defaultdict

# ── Modifier mask → readable string ──────────────────────────────────────────
def mod_str(mask: int) -> str:
    parts = []
    if mask & 64: parts.append("Super")
    if mask & 1:  parts.append("Shift")
    if mask & 4:  parts.append("Ctrl")
    if mask & 8:  parts.append("Alt")
    return " + ".join(parts)

# ── Key name normalisation ────────────────────────────────────────────────────
KEY_MAP = {
    "Return": "Enter",  "comma": ",",    "period": ".",   "semicolon": ";",
    "space":  "Space",  "escape": "Esc", "Tab": "Tab",
    "left": "←",        "right": "→",    "up": "↑",       "down": "↓",
    "XF86AudioRaiseVolume": "Vol↑",  "XF86AudioLowerVolume": "Vol↓",
    "XF86AudioMute":    "Mute",      "XF86AudioPlay":     "Play/Pause",
    "XF86AudioNext":    "Next",      "XF86AudioPrev":     "Prev",
    "XF86AudioStop":    "Stop",
    "XF86MonBrightnessUp": "Bright↑","XF86MonBrightnessDown": "Bright↓",
    "mouse_up":  "Scroll↑",  "mouse_down": "Scroll↓",
    "mouse:272": "LClick",   "mouse:273":  "RClick",
}
# Keycodes used when hyprctl reports keycode instead of a key name (key == "")
KEYCODE_MAP = {
    233: "Bright↑",
    232: "Bright↓",
}
def fmt_key(key: str, keycode: int = 0) -> str:
    if not key and keycode:
        return KEYCODE_MAP.get(keycode, f"key:{keycode}")
    return KEY_MAP.get(key, key)

# ── Canonical direction from an arg string ────────────────────────────────────
def canonical_dir(arg: str) -> str | None:
    a = arg.strip().lower()
    if a in ("l", "left"):  return "←"
    if a in ("r", "right"): return "→"
    if a in ("u", "up"):    return "↑"
    if a in ("d", "down"):  return "↓"
    if a in ("prev", "-1"): return "←"
    if a in ("next", "+1"): return "→"
    try:
        dx, dy = map(int, a.split())
        if dx < 0: return "←"
        if dx > 0: return "→"
        if dy < 0: return "↑"
        if dy > 0: return "↓"
    except Exception:
        pass
    return None

# ── Dispatcher → human description ───────────────────────────────────────────
def fmt_action(dispatcher: str, arg: str) -> str | None:
    a = arg.strip()
    match dispatcher:
        case "exec":
            return re.sub(r"^sh\s+-c\s+'(.+)'$", r"\1", a)
        case "killactive":                  return "Close window"
        case "fullscreen":                  return "Fullscreen"
        case "togglefloating":              return "Toggle float"
        case "movetoworkspace":             return f"Move window → workspace {a}"
        case "split-workspace":             return f"Switch to workspace {a}"
        case "split-movetoworkspacesilent": return f"Move window → workspace {a} (silent)"
        case "split-grabroguewindows":      return "Grab windows orphaned by disconnected monitor"
        case "split-cycleworkspaces":
            sym = "→" if a in ("+1", "next") else "←"
            return f"Cycle workspaces {sym}"
        case "movefocus":
            d = canonical_dir(a)
            return f"Move focus {d}" if d else f"Move focus {a}"
        case "movewindow":
            d = canonical_dir(a)
            return f"Move window {d}" if d else f"Move window {a}"
        case "split-changemonitorsilent":
            d = canonical_dir(a)
            return f"Move window {d} monitor (silent)" if d else f"Move window to {a} monitor (silent)"
        case "resizeactive":
            try:
                dx, dy = map(int, a.split())
                parts = []
                if dx: parts.append(f"{'→' if dx > 0 else '←'} {abs(dx)}px")
                if dy: parts.append(f"{'↓' if dy > 0 else '↑'} {abs(dy)}px")
                return "Resize  " + "  ".join(parts)
            except Exception:
                return f"Resize {a}"
        case "moveactive":
            try:
                dx, dy = map(int, a.split())
                arrows = ("→" if dx > 0 else "←" if dx < 0 else "") + \
                         ("↓" if dy > 0 else "↑" if dy < 0 else "")
                return f"Move floating {arrows}"
            except Exception:
                return f"Move floating {a}"
        case "cyclenext":         return f"Cycle window {'← prev' if 'prev' in a else '→ next'}"
        case "bringactivetotop":  return None   # always paired with cyclenext — suppress
        case "layoutmsg":         return f"Layout: {a}"
        case "dpms":              return f"Display power: {a}"
        case "workspace":         return f"Switch to workspace {a}"
        case _:                   return f"{dispatcher} {a}".strip()

# ── Category assignment ───────────────────────────────────────────────────────
CAT_MAP = {
    "exec":                          "Launch",
    "killactive":                    "Window",
    "fullscreen":                    "Window",
    "togglefloating":                "Window",
    "movetoworkspace":               "Window",
    "cyclenext":                     "Window",
    "layoutmsg":                     "Window",
    "movefocus":                     "Focus",
    "movewindow":                    "Focus",
    "resizeactive":                  "Resize",
    "moveactive":                    "Float",
    "split-workspace":               "Workspace",
    "split-movetoworkspacesilent":   "Workspace",
    "split-cycleworkspaces":         "Workspace",
    "split-changemonitorsilent":     "Monitor",
    "split-grabroguewindows":        "Monitor",
    "dpms":                          "System",
    "workspace":                     "Workspace",
}
CAT_ORDER = ["Launch", "Window", "Focus", "Resize", "Float",
             "Workspace", "Monitor", "System", "Other"]

# ── Collapse sequential workspace groups (1–10) ───────────────────────────────
def collapse_workspace_groups(raw: list) -> tuple[set, list]:
    skip: set[int] = set()
    extra: list[tuple] = []

    for disp in ("split-workspace", "split-movetoworkspacesilent"):
        by_mask: dict[int, list] = defaultdict(list)
        for b in raw:
            if b["dispatcher"] == disp:
                by_mask[b["modmask"]].append(b)

        for mask, members in by_mask.items():
            numeric = []
            for m in members:
                try:
                    numeric.append((int(m["arg"]), m))
                except ValueError:
                    pass
            if len(numeric) < 3:
                continue
            numeric.sort()
            vals = [v for v, _ in numeric]
            if vals != list(range(min(vals), max(vals) + 1)):
                continue

            for _, m in numeric:
                skip.add(id(m))

            keys     = [fmt_key(m["key"], m.get("keycode", 0)) for _, m in numeric]
            mod      = mod_str(mask)
            bind_str = f"{mod} + {keys[0]}–{keys[-1]}" if mod else f"{keys[0]}–{keys[-1]}"
            desc = (
                f"Switch to workspace {vals[0]}–{vals[-1]}" if disp == "split-workspace"
                else f"Move window → workspace {vals[0]}–{vals[-1]} (silent)"
            )
            extra.append(("Workspace", bind_str, desc, "", ""))

    return skip, extra

# ── Collapse arrow-direction groups ───────────────────────────────────────────
# 4-directional: movefocus / movewindow / resizeactive / moveactive
# 2-directional: split-changemonitorsilent (prev/next share same modmask)
DISPATCHERS_4 = {"movefocus", "movewindow", "resizeactive", "moveactive"}
DISPATCHERS_2 = {"split-changemonitorsilent"}

ARROW_LABELS_4 = {
    "movefocus":   "Move focus",
    "movewindow":  "Move window",
    "resizeactive":"Resize window",
    "moveactive":  "Move floating",
}

def collapse_arrow_groups(raw: list) -> tuple[set, list]:
    skip: set[int] = set()
    extra: list[tuple] = []

    groups: dict[tuple, list] = defaultdict(list)
    for b in raw:
        if b["dispatcher"] in DISPATCHERS_4 | DISPATCHERS_2:
            groups[(b["dispatcher"], b["modmask"])].append(b)

    for (disp, mask), members in groups.items():
        dir_map: dict[str, dict] = {}
        for m in members:
            d = canonical_dir(m["arg"])
            if d:
                dir_map[d] = m

        if disp in DISPATCHERS_4 and {"←", "→", "↑", "↓"} <= dir_map.keys():
            for m in members:
                if canonical_dir(m["arg"]) in {"←", "→", "↑", "↓"}:
                    skip.add(id(m))
            mod      = mod_str(mask)
            bind_str = f"{mod} + ↑↓←→" if mod else "↑↓←→"
            desc     = f"{ARROW_LABELS_4[disp]} ↑↓←→"
            cat      = CAT_MAP.get(disp, "Other")
            extra.append((cat, bind_str, desc, "", ""))

        elif disp in DISPATCHERS_2 and {"←", "→"} <= dir_map.keys():
            for m in members:
                if canonical_dir(m["arg"]) in {"←", "→"}:
                    skip.add(id(m))
            mod      = mod_str(mask)
            bind_str = f"{mod} + ←→" if mod else "←→"
            extra.append(("Monitor", bind_str, "Move window ←→ monitor (silent)", "", ""))

    return skip, extra

# ── ANSI helpers ──────────────────────────────────────────────────────────────
DIM   = "\033[2m"
CYAN  = "\033[36m"
BOLD  = "\033[1m"
RESET = "\033[0m"

def strip_ansi(s: str) -> str:
    return re.sub(r"\033\[[0-9;]*m", "", s)

# ── Main ──────────────────────────────────────────────────────────────────────
def main() -> None:
    try:
        raw: list = json.loads(subprocess.check_output(
            ["hyprctl", "binds", "-j"], stderr=subprocess.DEVNULL))
    except Exception as exc:
        print(f"show-keybinds: failed to read hyprctl binds: {exc}", file=sys.stderr)
        sys.exit(1)

    ws_skip,    ws_extra    = collapse_workspace_groups(raw)
    arrow_skip, arrow_extra = collapse_arrow_groups(raw)
    skip = ws_skip | arrow_skip

    entries: list[tuple] = []
    for b in raw:
        if id(b) in skip:
            continue
        desc = fmt_action(b["dispatcher"], b["arg"])
        if desc is None:
            continue
        cat      = CAT_MAP.get(b["dispatcher"], "Other")
        mod      = mod_str(b["modmask"])
        key      = fmt_key(b["key"], b.get("keycode", 0))
        bind_str = f"{mod} + {key}" if mod else key
        entries.append((cat, bind_str, desc, b["dispatcher"], b["arg"]))

    for cat, bind_str, desc, *rest in (ws_extra + arrow_extra):
        entries.append((cat, bind_str, desc, "", ""))

    entries.sort(key=lambda e: (
        CAT_ORDER.index(e[0]) if e[0] in CAT_ORDER else 99,
        e[1],
    ))

    cat_w  = max(len(e[0]) for e in entries)
    bind_w = max(len(e[1]) for e in entries)

    header = (f"{BOLD}{'':>{cat_w}}  "
              f"{'Keybind':<{bind_w}}  "
              f"Action{RESET}")

    lines:     list[tuple[str, str, str]] = []
    clean_map: dict[str, tuple[str, str]] = {}

    for cat, bind_str, desc, dispatcher, arg in entries:
        ansi  = f"{DIM}{cat:>{cat_w}}{RESET}  {CYAN}{bind_str:<{bind_w}}{RESET}  {desc}"
        clean = f"{cat:>{cat_w}}  {bind_str:<{bind_w}}  {desc}"
        lines.append((ansi, dispatcher, arg))
        clean_map[clean] = (dispatcher, arg)

    fzf_input = "\n".join(line for line, _, _ in lines)

    proc = subprocess.run(
        ["fzf", "--ansi",
         "--prompt=  keybinds ❯  ",
         "--height=100%",
         "--border=none",
         "--layout=reverse",
         f"--header={header}",
         "--header-first",
         "--no-sort",
         "--bind=enter:accept,esc:abort"],
        input=fzf_input, text=True, capture_output=True,
    )

    if proc.returncode != 0:
        sys.exit(0)

    chosen_clean = strip_ansi(proc.stdout.strip())
    match        = clean_map.get(chosen_clean)
    if not match:
        sys.exit(0)

    dispatcher, arg = match
    if not dispatcher:
        sys.exit(0)   # reference-only entry (collapsed range)

    if dispatcher == "exec":
        subprocess.Popen(["hyprctl", "dispatch", "exec", "--", arg])
    else:
        cmd = ["hyprctl", "dispatch", dispatcher]
        if arg:
            cmd.append(arg)
        subprocess.Popen(cmd)


if __name__ == "__main__":
    main()