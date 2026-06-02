#!/usr/bin/env bash
# Usage:
#   my-nixdump                 → dump all files
#   my-nixdump nvidia intel    → AND match (default)
#   my-nixdump -o nvidia intel → OR match
#   my-nixdump -a nvidia intel → AND match explicitly
#   my-nixdump -h              → help

cd ~/nixos-config || exit 1

mode="and"
output=$(mktemp /tmp/nixos-config-XXXX.txt)

show_help() {
  cat <<EOF
Usage: my-nixdump [options] [keywords...]

Options:
  -a        Match ALL keywords (AND) [default]
  -o        Match ANY keyword (OR)
  -h        Show this help

Examples:
  my-nixdump nvidia intel
  my-nixdump -o nvidia intel
  my-nixdump -a audio pipewire
EOF
}

# Parse flags
while getopts ":hoa" opt; do
  case "$opt" in
    h)
      show_help
      exit 0
      ;;
    o)
      mode="or"
      ;;
    a)
      mode="and"
      ;;
    \?)
      echo "Unknown option: -$OPTARG"
      show_help
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))
keywords=("$@")

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
cp "$output" ~/nixos-config-dump.txt