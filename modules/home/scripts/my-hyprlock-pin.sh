#!/usr/bin/env bash
# Handler for hyprlock's numeric PIN keypad (see modules/home/hyprland/hyprlock.nix).
#
# Each on-screen digit button calls:
#   PIN_LOGIN_LENGTH=<n> my-hyprlock-pin press <digit>
# The dot-indicator label polls:
#   my-hyprlock-pin status
#
# Important: this script never sees or checks the real PIN. It just "types"
# each tapped digit into hyprlock's normal (hidden) password prompt via a
# virtual keyboard, and hits Enter once the expected number of digits has
# been entered. The actual PIN comparison happens inside PAM
# (modules/core/security.nix), so a wrong PIN just fails like a wrong
# password normally would -- hyprlock's own $FAIL / $ATTEMPTS labels pick
# that up automatically.
#
# Only the digit count is tracked here, for the dot indicator. The digit
# itself briefly appears in this process's argv (and so in things like
# `ps`) while it's being sent -- fine for a low-stakes PIN, but worth
# knowing if you're reusing this for anything you actually care about.

set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/hyprlock-pin"
COUNT_FILE="$STATE_DIR/count"
STATUS_FILE="$STATE_DIR/status"
PIN_LENGTH="${PIN_LOGIN_LENGTH:-4}"

mkdir -p -m 700 "$STATE_DIR"
[ -f "$COUNT_FILE" ] || echo 0 > "$COUNT_FILE"
[ -f "$STATUS_FILE" ] || : > "$STATUS_FILE"

case "${1:-}" in
  press)
    digit="${2:-}"
    [[ "$digit" =~ ^[0-9]$ ]] || exit 0

    wtype -- "$digit"

    count=$(( $(cat "$COUNT_FILE") + 1 ))
    echo "$count" > "$COUNT_FILE"
    printf '%*s' "$count" '' | tr ' ' '*' > "$STATUS_FILE"

    if [ "$count" -ge "$PIN_LENGTH" ]; then
      echo 0 > "$COUNT_FILE"
      wtype -P Return -p Return
      # Clear the dots shortly after submitting so a wrong attempt doesn't
      # leave a full row of dots sitting on screen; $FAIL/$ATTEMPTS (added
      # as their own label) take over from here.
      ( sleep 1.2
        if pgrep -x hyprlock > /dev/null 2>&1; then
          : > "$STATUS_FILE"
        fi
      ) & disown
    fi
    ;;
  status)
    cat "$STATUS_FILE" 2>/dev/null || true
    ;;
  reset)
    echo 0 > "$COUNT_FILE"
    : > "$STATUS_FILE"
    ;;
  *)
    echo "usage: my-hyprlock-pin {press <digit>|status|reset}" >&2
    exit 1
    ;;
esac
