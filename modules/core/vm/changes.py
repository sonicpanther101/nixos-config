#!/usr/bin/env python3
"""
Render the differences between two versions of a config tree as Markdown that
can be pasted straight into a chat reply.

Format rules (these are the whole point of the script):
  * One section per changed file, headed by its path relative to the repo root.
  * Removed lines and added lines live in SEPARATE fenced code blocks.
  * Lines inside the blocks are shown verbatim, with NO leading "-" / "+".
  * Every hunk says where it is (original line numbers) so it can be located.

Usage:
  changes.py BEFORE AFTER [--max-lines N]

BEFORE / AFTER may each be a directory or a .zip file. If an archive or folder
contains a single top-level directory (e.g. "nixos-config/"), the script
descends into it automatically so paths line up between versions.
"""

import argparse
import difflib
import hashlib
import os
import sys
import tempfile
import zipfile

IGNORED_DIRS = {".git", "__MACOSX", ".direnv"}
IGNORED_FILES = {".DS_Store"}

# "Full updated file" block (copy-paste convenience for files with many small edits)
SMALL_HUNK_MAX_LINES = 10    # a hunk is "small" if both its Removed and Added side are <= this
FULL_FILE_MIN_SMALL = 3      # this many small hunks (i.e. more than 2) triggers the block
FULL_FILE_MAX_LINES = 600    # above this, print a one-line note instead of the block

LANG_BY_EXT = {
    ".nix": "nix",
    ".lua": "lua",
    ".sh": "bash",
    ".bash": "bash",
    ".zsh": "zsh",
    ".md": "markdown",
    ".json": "json",
    ".css": "css",
    ".c": "c",
    ".h": "c",
    ".xml": "xml",
    ".toml": "toml",
    ".yaml": "yaml",
    ".yml": "yaml",
    ".py": "python",
    ".conf": "ini",
    ".lock": "json",
    ".txt": "text",
}


# --------------------------------------------------------------------------- #
# Loading
# --------------------------------------------------------------------------- #
def materialise(path, tmp_roots):
    """Return a directory for `path`, extracting it first if it is a zip."""
    if os.path.isfile(path) and path.lower().endswith(".zip"):
        tmp = tempfile.mkdtemp(prefix="cfgdiff_")
        tmp_roots.append(tmp)
        with zipfile.ZipFile(path) as zf:
            zf.extractall(tmp)
            # extractall() drops permission bits; restore them so that
            # chmod +x changes on scripts are still detected.
            for info in zf.infolist():
                unix_mode = (info.external_attr >> 16) & 0o777
                if unix_mode and not info.is_dir():
                    os.chmod(os.path.join(tmp, info.filename), unix_mode)
        path = tmp
    if not os.path.isdir(path):
        sys.exit(f"error: {path!r} is not a directory or .zip")
    return descend_single_root(path)


def descend_single_root(path):
    """If `path` holds exactly one real directory, step into it."""
    while True:
        entries = [e for e in os.listdir(path) if e not in IGNORED_DIRS | IGNORED_FILES]
        if len(entries) == 1 and os.path.isdir(os.path.join(path, entries[0])):
            path = os.path.join(path, entries[0])
        else:
            return path


def walk(root):
    """Map relative path -> absolute path for every tracked-looking file."""
    out = {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in IGNORED_DIRS]
        for name in filenames:
            if name in IGNORED_FILES:
                continue
            full = os.path.join(dirpath, name)
            if os.path.islink(full):
                continue
            out[os.path.relpath(full, root)] = full
    return out


def read_bytes(p):
    with open(p, "rb") as fh:
        return fh.read()


def is_binary(data):
    return b"\x00" in data[:8192]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def mode_of(p):
    return os.stat(p).st_mode & 0o777


def lang_for(rel):
    base = os.path.basename(rel)
    if base == "flake.lock":
        return "json"
    return LANG_BY_EXT.get(os.path.splitext(base)[1].lower(), "text")


# --------------------------------------------------------------------------- #
# Rendering helpers
# --------------------------------------------------------------------------- #
def fence_for(text):
    """A backtick fence longer than any run of backticks inside `text`."""
    longest, run = 0, 0
    for ch in text:
        run = run + 1 if ch == "`" else 0
        longest = max(longest, run)
    return "`" * max(3, longest + 1)


def block(lines, lang, max_lines):
    """Return a fenced code block (verbatim lines, no diff markers)."""
    shown = lines[:max_lines] if max_lines else lines
    body = "\n".join(shown)
    fence = fence_for(body)
    out = f"{fence}{lang}\n{body}\n{fence}"
    if len(shown) < len(lines):
        out += f"\n_({len(lines) - len(shown)} more lines not shown here.)_"
    return out


def span(start, count):
    """Human-readable 1-based line span from a 0-based start and a count."""
    if count <= 0:
        return None
    return f"line {start + 1}" if count == 1 else f"lines {start + 1}–{start + count}"


def split_lines(data):
    return data.decode("utf-8", errors="replace").splitlines()


# --------------------------------------------------------------------------- #
# Per-file reports
# --------------------------------------------------------------------------- #
def report_modified(rel, old, new, old_mode, new_mode, max_lines):
    parts = [f"### `{rel}`"]
    notes = []
    if old_mode != new_mode:
        notes.append(f"File mode changed: {old_mode:o} → {new_mode:o}")

    if is_binary(old) or is_binary(new):
        notes.append(f"Binary file changed ({len(old)} → {len(new)} bytes). Contents not shown.")
        return "\n\n".join(parts + notes)

    a, b = split_lines(old), split_lines(new)
    lang = lang_for(rel)

    if a == b:
        if old != new:
            notes.append("Only whitespace / line-ending / trailing-newline differences.")
        return "\n\n".join(parts + notes) if notes else None

    ops = [op for op in difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes()
           if op[0] != "equal"]

    for n, (tag, i1, i2, j1, j2) in enumerate(ops, 1):
        removed, added = a[i1:i2], b[j1:j2]
        header_bits = []
        if removed:
            header_bits.append(f"original {span(i1, len(removed))}")
        else:
            anchor = a[i1 - 1].strip() if i1 > 0 else None
            where = f"after original line {i1}" if i1 > 0 else "at the top of the file"
            if anchor:
                where += f" (below `{anchor[:80]}`)"
            header_bits.append(f"inserted {where}")
        label = f"**Change {n} of {len(ops)}** — " + ", ".join(header_bits)
        section = [label]
        if removed:
            section.append("Removed:\n" + block(removed, lang, max_lines))
        if added:
            section.append("Added:\n" + block(added, lang, max_lines))
        parts.append("\n\n".join(section))

    small = sum(1 for _, i1, i2, j1, j2 in ops
                if i2 - i1 <= SMALL_HUNK_MAX_LINES and j2 - j1 <= SMALL_HUNK_MAX_LINES)
    if small >= FULL_FILE_MIN_SMALL:
        if len(b) > FULL_FILE_MAX_LINES:
            parts.append(f"_Full updated file not shown ({len(b)} lines, over the "
                         f"{FULL_FILE_MAX_LINES}-line limit); apply changes.diff or ask for it._")
        else:
            # Real file content, never trimmed (max_lines=0 means no cap).
            parts.append("**Full updated file**\n" + block(b, lang, 0))

    return "\n\n".join(parts + notes)


def report_added(rel, new, mode, max_lines):
    parts = [f"### `{rel}` — new file"]
    if is_binary(new):
        parts.append(f"Binary file ({len(new)} bytes). Contents not shown.")
    else:
        lines = split_lines(new)
        if not lines:
            parts.append("Empty file.")
        else:
            parts.append("Added:\n" + block(lines, lang_for(rel), max_lines))
    if mode & 0o111:
        parts.append(f"File mode: {mode:o} (executable)")
    return "\n\n".join(parts)


def report_removed(rel, old, max_lines):
    parts = [f"### `{rel}` — deleted file"]
    if is_binary(old):
        parts.append(f"Binary file ({len(old)} bytes). Contents not shown.")
    else:
        lines = split_lines(old)
        if lines:
            parts.append("Removed:\n" + block(lines, lang_for(rel), max_lines))
        else:
            parts.append("Was an empty file.")
    return "\n\n".join(parts)


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("before")
    ap.add_argument("after")
    ap.add_argument("--max-lines", type=int, default=300,
                    help="max lines shown per code block (0 = unlimited). Default 300.")
    args = ap.parse_args()

    tmp_roots = []
    try:
        before_root = materialise(args.before, tmp_roots)
        after_root = materialise(args.after, tmp_roots)
        before, after = walk(before_root), walk(after_root)

        only_before = sorted(set(before) - set(after))
        only_after = sorted(set(after) - set(before))
        common = sorted(set(before) & set(after))

        # Detect pure moves/renames: identical content, different path.
        removed_by_hash = {}
        for rel in only_before:
            removed_by_hash.setdefault(digest(read_bytes(before[rel])), []).append(rel)
        moves = []
        for rel in list(only_after):
            h = digest(read_bytes(after[rel]))
            if removed_by_hash.get(h):
                old_rel = removed_by_hash[h].pop(0)
                moves.append((old_rel, rel))
                only_before.remove(old_rel)
                only_after.remove(rel)

        sections = []
        for rel in common:
            old, new = read_bytes(before[rel]), read_bytes(after[rel])
            om, nm = mode_of(before[rel]), mode_of(after[rel])
            if old == new and om == nm:
                continue
            s = report_modified(rel, old, new, om, nm, args.max_lines)
            if s:
                sections.append(s)
        for rel in only_after:
            sections.append(report_added(rel, read_bytes(after[rel]), mode_of(after[rel]), args.max_lines))
        for rel in only_before:
            sections.append(report_removed(rel, read_bytes(before[rel]), args.max_lines))
        for old_rel, new_rel in moves:
            sections.append(f"### `{old_rel}` → `{new_rel}` — moved/renamed (contents unchanged)")

        if not sections:
            print("No files changed.")
            return

        total = len(sections)
        summary = (f"**{total} file{'s' if total != 1 else ''} changed** "
                   f"({len(only_after)} new, {len(only_before)} deleted, {len(moves)} moved).")
        print(summary + "\n")
        print("\n\n---\n\n".join(sections))
    finally:
        import shutil
        for t in tmp_roots:
            shutil.rmtree(t, ignore_errors=True)


if __name__ == "__main__":
    main()
