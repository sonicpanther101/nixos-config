#!/usr/bin/env bash
# Rotate the laptop panel. Used by the waybar power/rotation menu.
#   my-rotate-screen {upright|left|upside|right|cw|ccw|flip}
#
# `hyprctl keyword monitor ...` no longer works with the Lua config ("keyword
# can't work with non-legacy parsers"), so this re-applies the monitor with
# `hyprctl eval` + hl.monitor() instead.

OUTPUT="eDP-1"
SCALE="1.9"

current=$(hyprctl monitors -j | jq -r --arg o "$OUTPUT" '.[] | select(.name == $o) | .transform')
current=${current:-0}

case "$1" in
  upright) next=0 ;;
  left)    next=1 ;;
  upside)  next=2 ;;
  right)   next=3 ;;
  cw)      next=$(( (current + 1) % 4 )) ;;
  ccw)     next=$(( (current + 3) % 4 )) ;;
  flip)    next=$(( (current + 2) % 4 )) ;;
  *)
    echo "usage: my-rotate-screen {upright|left|upside|right|cw|ccw|flip}" >&2
    exit 1
    ;;
esac

hyprctl eval "hl.monitor({ output = \"$OUTPUT\", mode = \"preferred\", position = \"auto\", scale = $SCALE, transform = $next })"
