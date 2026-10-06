#!/usr/bin/env bash
# Print what changed in ~/nixos-config (vs. its `baseline` commit) as Markdown:
# one section per file, separate "Removed" / "Added" code blocks with no +/-
# markers, and a "Full updated file" block when a file has several small edits.
# (Same format as the nixos-config-change-report skill; the renderer is changes.py.)
#
# Used by goose-task to build the final report, and available to the agent as
# `vm-changes` for a preview. Extra arguments are passed to changes.py (--max-lines N).
set -euo pipefail

sandbox="${SANDBOX:-$HOME/nixos-config}"
cd "$sandbox" || { echo "vm-changes: $sandbox not found" >&2; exit 1; }

# Compare exactly what `git diff --cached HEAD` (changes.diff) would contain:
# the baseline commit vs. the staged tree (respects .gitignore, skips .git).
git add -A
tree=$(git write-tree)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/before" "$tmp/after"
git archive HEAD    | tar -x -C "$tmp/before"
git archive "$tree" | tar -x -C "$tmp/after"

python3 "$CHANGES_PY" "$tmp/before" "$tmp/after" "$@"
