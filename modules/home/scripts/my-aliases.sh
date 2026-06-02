#!/usr/bin/env python3
"""my-aliases — browse and run Zsh aliases with fzf."""

import os
import re
import subprocess
import sys

# ── Catppuccin Mocha palette (ANSI) ──────────────────────────────────────────
RST = "\033[0m"
DIM = "\033[2m"                     # dimmed grey   — category headers
CYN = "\033[36m"                    # sky           — alias name
GRY = "\033[0m"                     # grey          — expanded command

# ── Category rules (first match wins) ────────────────────────────────────────
def _categorise(name: str, cmd: str) -> str:
    n, c = name.lower(), cmd.lower()
    b = n + " " + c                   # combined string for keyword checks

    # Git — oh-my-zsh git plugin produces hundreds of short aliases
    if c.lstrip("'\"").startswith("git "):           return "Git"
    if re.match(r"^g[a-z]{1,4}$", n) and "git" in c: return "Git"

    # Nix & custom my-* scripts
    if "nix" in b or n.startswith("my-"):            return "Nix & Scripts"

    # Python / virtualenvs
    if any(k in b for k in ("python", "pip ", "venv", "piv", "psv")) \
            or n == "py":                            return "Python"

    # Editors
    if any(k in b for k in ("vim", "nvim", "codium", "code ", "nano", "hx ")):
        return "Editors"

    # File viewing / listing
    if any(k in b for k in ("eza", " ls", "ll ", "la ", "tree", "icat",
                             "bat ", "dsize", "psize", "gtrash", "tt ")):
        return "Files & Viewing"

    # Navigation
    if any(k in b for k in ("cd", "z ", "zoxide", "pwd", "findw")):
        return "Navigation"

    # Containers / infrastructure
    if any(k in b for k in ("docker", "kubectl", "helm", "k8s", "podman")):
        return "Containers"

    # System administration
    if any(k in b for k in ("sudo", "shutdown", "reboot", "systemctl",
                             "journalctl", "winboot", "usb ")):
        return "System"

    # Networking
    if any(k in b for k in ("ssh ", "curl", "wget", "ping", "nc ", "nmap",
                             "netstat", "ip ")):
        return "Network"

    # Archives
    if any(k in b for k in ("tar", "zip", "unzip", "7z", "rar", "gz")):
        return "Archives"

    # Oh-my-zsh built-ins that don't fit elsewhere (common ones)
    if any(k in b for k in ("grep", "egrep", "fgrep", "diff", "ls ")):
        return "Files & Viewing"

    return "Miscellaneous"


CATEGORY_ORDER = [
    "Nix & Scripts",
    "Python",
    "Editors",
    "Files & Viewing",
    "Navigation",
    "System",
    "Containers",
    "Network",
    "Archives",
    "Miscellaneous",
    "Git",
]

# ── Fetch aliases from a login Zsh session ───────────────────────────────────
def fetch_aliases() -> list[tuple[str, str]]:
    result = subprocess.run(
        ["zsh", "-c", 'source "$HOME/.zshrc" 2>/dev/null || true; alias'],
        capture_output=True, text=True, env=os.environ.copy(),
    )
    aliases: list[tuple[str, str]] = []
    # Zsh alias output formats:
    #   name='command with spaces'
    #   name=command
    pattern = re.compile(r"^([^=\s]+)=(.+)$")
    for line in result.stdout.splitlines():
        m = pattern.match(line.strip())
        if not m:
            continue
        name = m.group(1)
        cmd  = m.group(2).strip("'\"")
        aliases.append((name, cmd))
    return aliases


# ── Build the fzf list ───────────────────────────────────────────────────────
def build_input(aliases: list[tuple[str, str]]) -> str:
    groups: dict[str, list[tuple[str, str]]] = {c: [] for c in CATEGORY_ORDER}
    for name, cmd in aliases:
        groups[_categorise(name, cmd)].append((name, cmd))

    lines: list[str] = []
    for category in CATEGORY_ORDER:
        items = sorted(groups.get(category, []), key=lambda x: x[0].lower())
        if not items:
            continue
        for name, cmd in items:
            # Cyan alias name, grey expanded command
            lines.append(f"{DIM}{category.title():>{15}}{RST}  {CYN}{name:<22}{RST}{cmd}")

    return "\n".join(lines)


# ── Main ─────────────────────────────────────────────────────────────────────
def main() -> None:
    aliases = fetch_aliases()
    if not aliases:
        print("No Zsh aliases found.", file=sys.stderr)
        sys.exit(1)

    alias_dict = {name: cmd for name, cmd in aliases}
    fzf_input  = build_input(aliases)

    proc = subprocess.run(
        [
            "fzf",
            "--ansi",
            "--prompt=  \033[35maliases ❯  ",
            "--height=100%",
            "--border=none",
            "--layout=reverse",
            f"--header=                 \033[31mAlias                 Command {RST}{DIM}- {RST}ENTER to execute · ESC to cancel",
            "--header-first",
            "--no-sort",
            # Catppuccin Mocha colours
            "--color=bg:#1e1e2e,bg+:#313244,fg:#cdd6f4,fg+:#cdd6f4",
            "--color=header:#89b4fa,info:#cba6f7,prompt:#89b4fa,pointer:#f5e0dc",
            "--color=marker:#b4befe,spinner:#f5e0dc,hl:#f38ba8,hl+:#f38ba8",
            "--bind=enter:accept,esc:abort",
        ],
        input=fzf_input,
        text=True,
        capture_output=True,
        check=False,
    )

    chosen = proc.stdout.strip()
    if not chosen:
        sys.exit(0)

    # Strip ANSI escapes and extract the alias name (first token)
    clean      = re.sub(r"\033\[[0-9;]*[mK]", "", chosen).strip()
    alias_name = clean.split()[0] if clean.split() else ""

    # Ignore category headers (not in the alias dict)
    if alias_name not in alias_dict:
        sys.exit(0)

    # Execute — replaces this process with a zsh that runs the alias.
    # Note: aliases that change directory (cd, z) won't affect the parent
    # shell; type the alias name manually in that case.
    os.execvp("zsh", ["zsh", "-i", "-c",
                       f'source "$HOME/.zshrc" 2>/dev/null; {alias_name}'])


if __name__ == "__main__":
    main()