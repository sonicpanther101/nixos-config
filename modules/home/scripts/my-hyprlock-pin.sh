#!/usr/bin/env bash
# Handler for hyprlock's numeric PIN keypad (see modules/home/hyprland/hyprlock.nix).
#
# Each on-screen digit button calls:
#   PIN_LOGIN_CODE=<base64> PIN_LOGIN_LENGTH=<n> my-hyprlock-pin press <digit>
# The dot-indicator label polls:
#   my-hyprlock-pin status
#
# No PAM, no keyboard injection: this script just accumulates the digits
# itself, and once it has as many as PIN_LOGIN_LENGTH, compares the buffer
# to the base64-decoded PIN. On a match it pkills hyprlock, which is enough
# to dismiss the lock screen on Hyprland. On a miss it clears the buffer and
# shows "Incorrect PIN" for a moment.
#
# This is intentionally not hardened: the PIN passes through this process's
# argv (visible briefly in `ps`) and sits base64-encoded in your Nix config.
# Fine for a low-stakes PIN, not a real secret.

set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/hyprlock-pin"
BUFFER_FILE="$STATE_DIR/buffer"
STATUS_FILE="$STATE_DIR/status"
PIN_LENGTH="${PIN_LOGIN_LENGTH:-4}"
PIN_LOGIN_CODE="$(cat ~/.passwd)"

mkdir -p -m 700 "$STATE_DIR"
[ -f "$BUFFER_FILE" ] || : > "$BUFFER_FILE"
[ -f "$STATUS_FILE" ] || : > "$STATUS_FILE"

case "${1:-}" in
  press)
    digit="${2:-}"
    [[ "$digit" =~ ^[0-9]$ ]] || exit 0

    printf '%s' "$digit" >> "$BUFFER_FILE"
    buf="$(cat "$BUFFER_FILE")"
    printf '%*s' "${#buf}" '' | tr ' ' '*' > "$STATUS_FILE"

    echo $buf > ~/log.txt

    if [ "${#buf}" -ge "$PIN_LENGTH" ]; then
      expected="$(printf '%s' "${PIN_LOGIN_CODE:-}" | base64 -d 2>/dev/null || true)"
      : > "$BUFFER_FILE"
      echo $expected
      echo $buf

      if [ -n "$expected" ] && [ "$buf" = "$expected" ]; then
        echo "Unlocking..." > "$STATUS_FILE"
        echo "Unlocking..."
        pkill -USR1 hyprlock || true
        my-hyprlock-pin reset
      else
        echo "Incorrect PIN" > "$STATUS_FILE"
        echo "Incorrect PIN"
        ( sleep 1
          : > "$STATUS_FILE"
        ) & disown
      fi
    fi
    ;;
  status)
    cat "$STATUS_FILE" 2>/dev/null || true
    ;;
  reset)
    : > "$BUFFER_FILE"
    : > "$STATUS_FILE"
    ;;
  *)
    echo "usage: my-hyprlock-pin {press <digit>|status|reset}" >&2
    exit 1
    ;;
esac
