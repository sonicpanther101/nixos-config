#!/usr/bin/env python3
"""
budget — savings goal tracker
Stores data in ~/.local/share/budget/budget.json

Keybinds:
  j/k or ↑/↓   navigate
  J/K           move item up/down
  a             add item (prompts for name + price)
  s             sub-item (add child to selected item)
  e             edit selected item
  d             delete selected item
  S             set savings amount
  q / Esc       quit
"""

import curses
import json
import os
import sys

DATA_DIR  = os.path.expanduser("~/.local/share/budget")
DATA_FILE = os.path.join(DATA_DIR, "budget.json")

# ── Catppuccin Mocha palette indices (set up in init_colors) ──────────────────
C_BG     = -1   # terminal default background (transparent)
C_FG     = 1    # cdd6f4  text
C_ACCENT = 2    # 89b4fa  blue — headers, borders
C_GREEN  = 3    # a6e3a1  filled bar / 100%
C_YELLOW = 4    # f9e2af  partial fill
C_RED    = 5    # f38ba8  price / delete hint
C_GREY   = 6    # 585b70  empty bar / dim text
C_MAUVE  = 7    # cba6f7  savings label
C_TEAL   = 8    # 94e2d5  sub-item indent marker
C_SEL_BG = 9    # 313244  selected row background


def load_data():
    os.makedirs(DATA_DIR, exist_ok=True)
    if os.path.exists(DATA_FILE):
        try:
            with open(DATA_FILE) as f:
                d = json.load(f)
                # Ensure required keys exist for older files
                d.setdefault("savings", 0)
                d.setdefault("items", [])
                return d
        except (json.JSONDecodeError, KeyError):
            pass
    return {"savings": 0, "items": []}


def save_data(data):
    os.makedirs(DATA_DIR, exist_ok=True)
    with open(DATA_FILE, "w") as f:
        json.dump(data, f, indent=2)


def total_price(item):
    """Recursive total: sum of sub-items if any, else own price."""
    if item.get("sub_items"):
        return sum(total_price(s) for s in item["sub_items"])
    return item.get("price", 0)


def flatten(items, depth=0):
    """Return list of (item, depth, parent_list, index_in_parent)."""
    rows = []
    for i, item in enumerate(items):
        rows.append((item, depth, items, i))
        if item.get("sub_items"):
            rows.extend(flatten(item["sub_items"], depth + 1))
    return rows


def calc_progress(data):
    """
    Fill items top-to-bottom (DFS leaf order) with savings.
    Returns dict keyed by id(item) → pct (0–100 float).
    """
    savings = data["savings"]
    pct = {}

    def fill(items):
        nonlocal savings
        for item in items:
            if item.get("sub_items"):
                fill(item["sub_items"])
                # parent pct = average of children
                children_pct = [pct.get(id(s), 0) for s in item["sub_items"]]
                pct[id(item)] = sum(children_pct) / len(children_pct) if children_pct else 0
            else:
                price = item.get("price", 0)
                if price <= 0:
                    pct[id(item)] = 100.0
                elif savings <= 0:
                    pct[id(item)] = 0.0
                elif savings >= price:
                    pct[id(item)] = 100.0
                    savings -= price
                else:
                    pct[id(item)] = savings / price * 100
                    savings = 0

    fill(data["items"])
    return pct


def bar(pct, width=20):
    """Return (filled_str, empty_str) for a progress bar of given width."""
    filled = round(pct / 100 * width)
    filled = max(0, min(width, filled))
    return "█" * filled, "░" * (width - filled)


def prompt(stdscr, question, prefill=""):
    """Single-line input prompt at the bottom of the screen. Returns string or None."""
    h, w = stdscr.getmaxyx()
    curses.echo()
    curses.curs_set(1)
    stdscr.move(h - 1, 0)
    stdscr.clrtoeol()
    stdscr.attron(curses.color_pair(C_ACCENT) | curses.A_BOLD)
    stdscr.addstr(h - 1, 0, question)
    stdscr.attroff(curses.color_pair(C_ACCENT) | curses.A_BOLD)
    col = len(question)
    if prefill:
        stdscr.addstr(h - 1, col, prefill)
    stdscr.refresh()
    try:
        raw = stdscr.getstr(h - 1, col, w - col - 1)
        result = raw.decode("utf-8").strip()
    except Exception:
        result = None
    curses.noecho()
    curses.curs_set(0)
    return result if result is not None else prefill


def draw(stdscr, data, cursor, scroll, msg=""):
    stdscr.erase()
    h, w = stdscr.getmaxyx()

    rows   = flatten(data["items"])
    pct    = calc_progress(data)
    BAR_W  = min(24, w // 4)

    # ── Header ────────────────────────────────────────────────────────────────
    total_items = sum(total_price(i) for i in data["items"])
    savings     = data["savings"]
    header = f" 󰈆  Savings: ${savings:,.2f}   /   Total: ${total_items:,.2f}"
    stdscr.attron(curses.color_pair(C_ACCENT) | curses.A_BOLD)
    stdscr.addnstr(0, 0, header.ljust(w), w)
    stdscr.attroff(curses.color_pair(C_ACCENT) | curses.A_BOLD)

    # ── Rows ──────────────────────────────────────────────────────────────────
    visible = h - 3  # reserve header + help line + prompt line
    for screen_y, row_i in enumerate(range(scroll, min(scroll + visible, len(rows)))):
        item, depth, _, _ = rows[row_i]
        y = screen_y + 1
        selected = (row_i == cursor)

        p       = pct.get(id(item), 0)
        price   = total_price(item)
        b_fill, b_empty = bar(p, BAR_W)
        label   = ("  " * depth) + ("└ " if depth > 0 else "") + item.get("label", "?")
        price_s = f"${price:,.0f}" if price else "  —  "
        pct_s   = f"{p:5.1f}%"

        # colour for bar fill
        if p >= 100:
            bar_col = curses.color_pair(C_GREEN)
        elif p > 0:
            bar_col = curses.color_pair(C_YELLOW)
        else:
            bar_col = curses.color_pair(C_GREY)

        if selected:
            stdscr.attron(curses.color_pair(C_SEL_BG))
            stdscr.addnstr(y, 0, " " * w, w)
            stdscr.attroff(curses.color_pair(C_SEL_BG))

        col = 1
        # label
        label_attr = (curses.color_pair(C_SEL_BG) if selected else 0) | curses.A_BOLD
        max_label  = w - BAR_W - 18
        stdscr.attron(label_attr)
        stdscr.addnstr(y, col, label[:max_label].ljust(max_label), max_label)
        stdscr.attroff(label_attr)
        col += max_label

        # price
        price_attr = curses.color_pair(C_RED) | (curses.color_pair(C_SEL_BG) if selected else 0)
        stdscr.attron(price_attr)
        stdscr.addnstr(y, col, price_s.rjust(8), 8)
        stdscr.attroff(price_attr)
        col += 8

        # pct
        stdscr.attron(bar_col)
        stdscr.addnstr(y, col, pct_s, 7)
        stdscr.attroff(bar_col)
        col += 7

        # bar
        stdscr.attron(bar_col)
        stdscr.addnstr(y, col, b_fill, BAR_W)
        stdscr.attroff(bar_col)
        col += len(b_fill)
        stdscr.attron(curses.color_pair(C_GREY))
        stdscr.addnstr(y, col, b_empty, BAR_W - len(b_fill))
        stdscr.attroff(curses.color_pair(C_GREY))

    # ── Help bar ──────────────────────────────────────────────────────────────
    help_text = " a add  s sub  e edit  d del  S savings  J/K move  q quit"
    stdscr.attron(curses.color_pair(C_GREY))
    stdscr.addnstr(h - 2, 0, help_text.ljust(w), w)
    stdscr.attroff(curses.color_pair(C_GREY))

    # ── Status / message ─────────────────────────────────────────────────────
    if msg:
        stdscr.attron(curses.color_pair(C_MAUVE))
        stdscr.addnstr(h - 1, 0, msg[:w], w)
        stdscr.attroff(curses.color_pair(C_MAUVE))

    stdscr.refresh()


def init_colors():
    curses.start_color()
    curses.use_default_colors()

    def rgb(r, g, b):
        # curses uses 0–1000 scale
        return int(r / 255 * 1000), int(g / 255 * 1000), int(b / 255 * 1000)

    if curses.can_change_color():
        curses.init_color(20, *rgb(0xcd, 0xd6, 0xf4))   # fg
        curses.init_color(21, *rgb(0x89, 0xb4, 0xfa))   # blue
        curses.init_color(22, *rgb(0xa6, 0xe3, 0xa1))   # green
        curses.init_color(23, *rgb(0xf9, 0xe2, 0xaf))   # yellow
        curses.init_color(24, *rgb(0xf3, 0x8b, 0xa8))   # red
        curses.init_color(25, *rgb(0x58, 0x5b, 0x70))   # grey
        curses.init_color(26, *rgb(0xcb, 0xa6, 0xf7))   # mauve
        curses.init_color(27, *rgb(0x94, 0xe2, 0xd5))   # teal
        curses.init_color(28, *rgb(0x31, 0x32, 0x44))   # sel bg
        curses.init_color(29, *rgb(0x1e, 0x1e, 0x2e))   # base bg

        curses.init_pair(C_FG,     20, -1)
        curses.init_pair(C_ACCENT, 21, -1)
        curses.init_pair(C_GREEN,  22, -1)
        curses.init_pair(C_YELLOW, 23, -1)
        curses.init_pair(C_RED,    24, -1)
        curses.init_pair(C_GREY,   25, -1)
        curses.init_pair(C_MAUVE,  26, -1)
        curses.init_pair(C_TEAL,   27, -1)
        curses.init_pair(C_SEL_BG, 20, 28)
    else:
        # Fallback for terminals that can't change colours
        curses.init_pair(C_FG,     curses.COLOR_WHITE,   -1)
        curses.init_pair(C_ACCENT, curses.COLOR_BLUE,    -1)
        curses.init_pair(C_GREEN,  curses.COLOR_GREEN,   -1)
        curses.init_pair(C_YELLOW, curses.COLOR_YELLOW,  -1)
        curses.init_pair(C_RED,    curses.COLOR_RED,     -1)
        curses.init_pair(C_GREY,   curses.COLOR_BLACK,   -1)
        curses.init_pair(C_MAUVE,  curses.COLOR_MAGENTA, -1)
        curses.init_pair(C_TEAL,   curses.COLOR_CYAN,    -1)
        curses.init_pair(C_SEL_BG, curses.COLOR_BLACK,   curses.COLOR_WHITE)


def main(stdscr):
    curses.curs_set(0)
    curses.noecho()
    stdscr.keypad(True)
    init_colors()

    data   = load_data()
    cursor = 0
    scroll = 0
    msg    = ""

    def clamp_cursor():
        nonlocal cursor
        rows = flatten(data["items"])
        cursor = max(0, min(cursor, len(rows) - 1))

    def adjust_scroll():
        nonlocal scroll
        h = stdscr.getmaxyx()[0]
        visible = h - 3
        if cursor < scroll:
            scroll = cursor
        elif cursor >= scroll + visible:
            scroll = cursor - visible + 1

    while True:
        clamp_cursor()
        adjust_scroll()
        draw(stdscr, data, cursor, scroll, msg)
        msg = ""

        key = stdscr.getch()
        rows = flatten(data["items"])

        # ── Navigation ────────────────────────────────────────────────────────
        if key in (ord("k"), curses.KEY_UP):
            cursor = max(0, cursor - 1)

        elif key in (ord("j"), curses.KEY_DOWN):
            cursor = min(len(rows) - 1, cursor + 1)

        # ── Move item up/down within its parent ───────────────────────────────
        elif key == ord("K") and rows:
            _, _, parent, idx = rows[cursor]
            if idx > 0:
                parent[idx], parent[idx - 1] = parent[idx - 1], parent[idx]
                cursor -= 1
                save_data(data)

        elif key == ord("J") and rows:
            _, _, parent, idx = rows[cursor]
            if idx < len(parent) - 1:
                parent[idx], parent[idx + 1] = parent[idx + 1], parent[idx]
                cursor += 1
                save_data(data)

        # ── Add top-level item ────────────────────────────────────────────────
        elif key == ord("a"):
            name = prompt(stdscr, "New item name: ")
            if name:
                price_s = prompt(stdscr, f"Price for '{name}': $")
                try:
                    price = float(price_s or "0")
                except ValueError:
                    price = 0
                data["items"].append({"label": name, "price": price})
                cursor = len(flatten(data["items"])) - 1
                save_data(data)
                msg = f"Added '{name}'"

        # ── Add sub-item to selected ──────────────────────────────────────────
        elif key == ord("s") and rows:
            item, _, _, _ = rows[cursor]
            name = prompt(stdscr, f"Sub-item of '{item['label']}': ")
            if name:
                price_s = prompt(stdscr, f"Price for '{name}': $")
                try:
                    price = float(price_s or "0")
                except ValueError:
                    price = 0
                item.setdefault("sub_items", []).append({"label": name, "price": price})
                save_data(data)
                msg = f"Added sub-item '{name}'"
                clamp_cursor()

        # ── Edit selected ─────────────────────────────────────────────────────
        elif key == ord("e") and rows:
            item, _, _, _ = rows[cursor]
            new_name = prompt(stdscr, "Edit name: ", item.get("label", ""))
            if new_name:
                item["label"] = new_name
            # Only edit price for leaf nodes (no sub-items)
            if not item.get("sub_items"):
                price_s = prompt(stdscr, "Edit price: $", str(item.get("price", 0)))
                try:
                    item["price"] = float(price_s or "0")
                except ValueError:
                    pass
            save_data(data)
            msg = "Updated"

        # ── Delete selected ───────────────────────────────────────────────────
        elif key == ord("d") and rows:
            item, _, parent, idx = rows[cursor]
            confirm = prompt(stdscr, f"Delete '{item['label']}'? (y/N): ")
            if confirm and confirm.lower() == "y":
                parent.pop(idx)
                clamp_cursor()
                save_data(data)
                msg = f"Deleted '{item['label']}'"

        # ── Set savings ───────────────────────────────────────────────────────
        elif key == ord("S"):
            s = prompt(stdscr, "Savings amount: $", str(data["savings"]))
            try:
                data["savings"] = float(s or "0")
                save_data(data)
                msg = f"Savings set to ${data['savings']:,.2f}"
            except ValueError:
                msg = "Invalid amount"

        # ── Quit ──────────────────────────────────────────────────────────────
        elif key in (ord("q"), 27):  # q or Esc
            break


if __name__ == "__main__":
    try:
        curses.wrapper(main)
    except KeyboardInterrupt:
        pass