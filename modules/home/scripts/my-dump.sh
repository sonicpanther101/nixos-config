#!/usr/bin/env bash
# Usage:
#   my-dump                          → dump all files from ~/nixos-config
#   my-dump ~/other                  → dump all files from ~/other
#   my-dump nvidia intel             → AND match (default)
#   my-dump ~/other nvidia intel     → AND match in ~/other
#   my-dump -o nvidia intel          → OR match
#   my-dump -a nvidia intel          → AND match explicitly
#   my-dump -d ~/other nvidia        → explicit folder
#   my-dump -z ~/other               → zip the folder
#   my-dump -h                       → help

mode="and"
target=""
do_zip=false

show_help() {
  cat <<EOF
Usage: my-nixdump [options] [folder] [keywords...]

Options:
  -a        Match ALL keywords (AND) [default]
  -o        Match ANY keyword (OR)
  -d DIR    Target directory (default: ~/nixos-config)
  -z        Zip the target directory (ignores keywords)
  -h        Show this help

If the first positional argument is an existing directory, it is used as the target.

Examples:
  my-dump
  my-dump ~/my-project
  my-dump nvidia intel
  my-dump ~/my-project -o audio pipewire
  my-dump -d ~/my-project -a nvidia intel
  my-dump -z ~/my-project
EOF
}

# Parse flags
while getopts ":hoazd:" opt; do
  case "$opt" in
    h) show_help; exit 0 ;;
    o) mode="or" ;;
    a) mode="and" ;;
    z) do_zip=true ;;
    d) target="$OPTARG" ;;
    \?) echo "Unknown option: -$OPTARG" >&2; show_help; exit 1 ;;
    :)  echo "Missing argument for -$OPTARG" >&2; exit 1 ;;
  esac
done

shift $((OPTIND - 1))

# If no explicit -d target and the first positional is a directory, use it
if [[ -z "$target" ]] && [[ $# -gt 0 ]] && [[ -d "$1" ]]; then
  target="$1"
  shift
fi

keywords=("$@")

# Default target
[[ -z "$target" ]] && target="$HOME/nixos-config"

if [[ ! -d "$target" ]]; then
  echo "Error: '$target' is not a directory" >&2
  exit 1
fi

# Normalize to absolute path, then cd
target="$(cd "$target" && pwd)"
cd "$target" || exit 1

folder_name=$(basename "$target")

if [[ "$do_zip" == true ]]; then
  zip_path="$HOME/${folder_name}.zip"
  rm -f "$zip_path"
  7z a "$zip_path" "$target"
  echo "Zipped to $zip_path"
  exit 0
fi

output=$(mktemp "/tmp/${folder_name}-XXXX.txt")

matches_file() {
  local file="$1"

  [[ ${#keywords[@]} -eq 0 ]] && return 0

  if [[ "$mode" == "and" ]]; then
    for kw in "${keywords[@]}"; do
      grep -qi "$kw" "$file" || return 1
    done
    return 0
  else
    for kw in "${keywords[@]}"; do
      grep -qi "$kw" "$file" && return 0
    done
    return 1
  fi
}

find . \
  \( -name "*.nix" -o -name "*.sh" -o -name "*.yaml" -o -name "*.md" \) \
  -not -path "*/.git/*" \
  | sort \
  | while read -r f; do
      if matches_file "$f"; then
        echo "========================================="
        echo "FILE: $f"
        echo "========================================="
        cat "$f"
        echo
      fi
    done > "$output"

echo "Written to $output"
wc -l "$output"
cp "$output" "$HOME/${folder_name}-dump.txt"
