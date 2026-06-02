#!/usr/bin/env bash
# Usage: my-nixdump          → whole config
#        my-nixdump audio    → only files matching keyword

cd ~/nixos-config
query="$1"

output=$(mktemp /tmp/nixos-config-XXXX.txt)

find . -name "*.nix" -o -name "*.sh" -o -name "*.yaml" -o -name "*.md" | \
  grep -v ".git" | sort | while read f; do
    if [[ -z "$query" ]] || grep -qi "$query" "$f"; then
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