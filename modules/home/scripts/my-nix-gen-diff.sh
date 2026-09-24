#!/usr/bin/env bash
#
# nix-gen-diff.sh — show the git diff (or just changed files) between two
# NixOS generations, by finding the commits my-install.sh made for them.
#
# my-install.sh commits with a message like:
#   "<msg>. Rebuilt <host>: Generation 841"
# so we just grep the log for "Generation <N>" to find the matching commit.
#
# Usage:
#   nix-gen-diff.sh [-s] [-r repo] <from_gen> <to_gen>
#
# Note: generation numbers are per-host, so the same number can exist on
# multiple machines (e.g. "desktop" and "laptop-2"). This script always
# matches on host + generation together, defaulting to the current
# hostname — use -H to look up generations for a different host.
#
# Options:
#   -s          Show only the list of changed files (git diff --stat) instead
#               of the full diff
#   -i          Show only the commit log (the "intent" behind each rebuild),
#               skip the diff/stat entirely
#   -r <path>   Path to the nixos-config repo (default: $NIXOS_CONFIG_DIR or
#               ~/nixos-config)
#   -H <host>   Host to match in the commit message (default: current
#               hostname, i.e. `hostname` output)
#   -d          Debug: list every commit mentioning "Generation N"
#   -h          Show this help
#
# Example:
#   nix-gen-diff.sh 841 855
#   nix-gen-diff.sh -s 841 855
#   nix-gen-diff.sh -i 841 855
#   nix-gen-diff.sh -H laptop-2 100 129

set -euo pipefail

repo="${NIXOS_CONFIG_DIR:-$HOME/nixos-config}"
stat_only=false
log_only=false
debug=false
host="$(hostname)"

usage() {
    sed -n '2,29p' "$0" | sed 's/^#//; s/^ //'
    exit 1
}

while getopts "sir:dH:h" opt; do
    case "$opt" in
        s) stat_only=true ;;
        i) log_only=true ;;
        r) repo="$OPTARG" ;;
        d) debug=true ;;
        H) host="$OPTARG" ;;
        h) usage ;;
        \?) usage ;;
    esac
done
shift $((OPTIND - 1))

if [[ $# -ne 2 ]]; then
    echo "Error: expected exactly 2 arguments (from_gen to_gen)" >&2
    usage
fi

from_gen="$1"
to_gen="$2"

for g in "$from_gen" "$to_gen"; do
    [[ "$g" =~ ^[0-9]+$ ]] || { echo "Error: '$g' is not a valid generation number" >&2; exit 1; }
done

[[ -d "$repo/.git" ]] || {
    echo "Error: '$repo' is not a git repo. Set NIXOS_CONFIG_DIR or use -r <path>." >&2
    exit 1
}

cd "$repo"

# Generation numbers are per-host (nixos-rebuild's counter resets per
# machine), so "Generation 855" is ambiguous across hosts — always match on
# "Rebuilt <host>: Generation N", not just the number.
#
# Find the most recent commit whose message mentions this exact host+gen
# (the [^0-9] guard avoids "Generation 8410" matching a search for "841").
# `|| true` matters: grep exits 1 on no match, and under pipefail that would
# otherwise trip `set -e` and kill the script with no output at all.
find_commit() {
    local gen="$1"
    git log --all --format='%H%x09%s' \
        | { grep -P "Rebuilt ${host}: Generation ${gen}([^0-9]|\$)" || true; } \
        | head -1 \
        | cut -f1
}

from_hash=$(find_commit "$from_gen")
to_hash=$(find_commit "$to_gen")

if [[ "$debug" == true ]]; then
    echo "--- debug: all commits mentioning 'Generation' (host filter: ${host}) ---" >&2
    git log --all --format='%h  %s' | grep -P 'Generation \d+' >&2
    echo "-------------------------------------------------------" >&2
fi

if [[ -z "$from_hash" ]]; then
    echo "Error: no commit found for generation $from_gen" >&2
    echo "(it may have scrolled out of git log, or was built with -c/-s/skip-git)" >&2
    exit 1
fi

if [[ -z "$to_hash" ]]; then
    echo "Error: no commit found for generation $to_gen" >&2
    echo "(it may have scrolled out of git log, or was built with -c/-s/skip-git)" >&2
    exit 1
fi

echo "Generation $from_gen -> commit ${from_hash:0:12}"
echo "Generation $to_gen   -> commit ${to_hash:0:12}"
echo

# Order chronologically (oldest first) regardless of which generation number
# was passed first, so the log/diff always reads forward in time.
# Use ancestry (not commit timestamps!) to determine order — timestamps can
# tie when commits land in the same second, which breaks the ordering.
if git merge-base --is-ancestor "$from_hash" "$to_hash" 2>/dev/null; then
    older_hash="$from_hash"; newer_hash="$to_hash"
elif git merge-base --is-ancestor "$to_hash" "$from_hash" 2>/dev/null; then
    older_hash="$to_hash"; newer_hash="$from_hash"
else
    echo "Warning: these two commits aren't on the same line of history" \
         "(one isn't an ancestor of the other) — skipping the commit log." >&2
    older_hash=""; newer_hash=""
fi

if [[ -n "$older_hash" ]]; then
    echo "--- Commits (intent behind each rebuild), oldest first ---"
    git log --reverse --format='* %h  %s' "${older_hash}..${newer_hash}"
    echo "------------------------------------------------------------"
    echo
fi

if [[ "$log_only" == true ]]; then
    exit 0
fi

if [[ "$stat_only" == true ]]; then
    git diff --stat "$from_hash" "$to_hash"
else
    git diff "$from_hash" "$to_hash"
fi
