# Usage: my-sha256 <url>

if [[ -z "$1" ]]; then
  echo "Usage: my-sha256 <url>"
  exit 1
fi

tmpfile=$(mktemp)
trap "rm -f $tmpfile" EXIT

curl -fsSL "$1" -o "$tmpfile" || { echo "Failed to download: $1"; exit 1; }

raw=$(nix hash file --type sha256 "$tmpfile")
wl-copy "$raw"
echo "Copied $raw to clipboard"