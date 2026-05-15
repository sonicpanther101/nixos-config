#!/usr/bin/env bash
# add-vscode-ext: generate a nix openVsxExtension snippet
#
# Usage:
#   add-vscode-ext <publisher> <name> [version]
#   add-vscode-ext https://open-vsx.org/extension/<publisher>/<name>
#   add-vscode-ext https://open-vsx.org/extension/<publisher>/<name>/<version>

set -euo pipefail

RED=$(tput setaf 1); GREEN=$(tput setaf 2)
CYAN=$(tput setaf 6); BOLD=$(tput bold); RESET=$(tput sgr0)

usage() {
  echo "${BOLD}Usage:${RESET}"
  echo "  add-vscode-ext <publisher> <name> [version]"
  echo "  add-vscode-ext https://open-vsx.org/extension/<publisher>/<name>"
  exit 1
}

[[ $# -lt 1 ]] && usage

# Parse args — URL or publisher name
if [[ "$1" == http* ]]; then
  url="${1%/}"
  IFS='/' read -ra parts <<< "${url#*open-vsx.org/extension/}"
  publisher="${parts[0]}"
  name="${parts[1]}"
  version="${parts[2]:-}"
else
  publisher="$1"
  name="${2:-}"
  version="${3:-}"
  [[ -z "$name" ]] && usage
fi

echo "${CYAN}→ Looking up ${BOLD}${publisher}.${name}${RESET}${CYAN} on Open VSX...${RESET}"

api_url="https://open-vsx.org/api/${publisher}/${name}${version:+/$version}"
meta=$(curl -fsSL "$api_url") || {
  echo "${RED}✗ Failed to reach Open VSX API. Are you online?${RESET}"
  exit 1
}

resolved_version=$(echo "$meta" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['version'])")
vsix_url=$(echo "$meta" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['files']['download'])")

echo "${CYAN}→ Found version ${BOLD}${resolved_version}${RESET}${CYAN}, fetching hash...${RESET}"
echo "nix-prefetch-url --type sha256 $vsix_url"

# Check if the URL contains '@' (platform-specific extension — illegal in nix store paths).
# In that case, download to a temp file and hash it directly.
fetch_name_line=""
if [[ "$vsix_url" == *"@"* ]]; then
  # Extract the filename from the URL and sanitise it (replace @ with -)
  raw_filename="${vsix_url##*/}"
  safe_filename="${raw_filename//@/-}"

  echo "${CYAN}→ Platform-specific extension detected, downloading to temp file...${RESET}"
  tmpfile=$(mktemp --suffix=.vsix)
  trap "rm -f $tmpfile" EXIT
  curl -fsSL "$vsix_url" -o "$tmpfile"

  # Hash the file and convert to SRI format
  raw_hash=$(nix-hash --type sha256 --flat "$tmpfile")
  sri=$(nix hash to-sri --type sha256 "$raw_hash")

  # We need fetchName so fetchurl uses the sanitised filename
  fetch_name_line="      fetchName = \"${safe_filename}\";"
else
  raw_hash=$(nix-prefetch-url --type sha256 "$vsix_url" 2>/dev/null | tail -1)
  sri=$(nix hash to-sri --type sha256 "$raw_hash")
fi

echo
echo "${GREEN}${BOLD}✓ Add this to extensions.nix:${RESET}"
echo
if [[ -n "$fetch_name_line" ]]; then
  echo "    (openVsxExtension {"
  echo "      publisher = \"${publisher}\"; name = \"${name}\"; version = \"${resolved_version}\";"
  echo "$fetch_name_line"
  echo "      sha256 = \"${sri}\";"
  echo "    })"
else
  echo "    (openVsxExtension {"
  echo "      publisher = \"${publisher}\"; name = \"${name}\"; version = \"${resolved_version}\";"
  echo "      sha256 = \"${sri}\";"
  echo "    })"
fi
echo