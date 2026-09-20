#!/usr/bin/env bash
set -euo pipefail

sock="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

jiggle() {
  wlrctl pointer move 1 1 || true
  wlrctl pointer move -1 -1 || true
}

# Jiggle once on startup so an already-open menu still gets registered.
jiggle

socat -U - "UNIX-CONNECT:${sock}" | while IFS= read -r line; do
  case "$line" in
    activewindow*|activewindowv2*|openwindow*|closewindow*|openlayer*|closelayer*)
      jiggle
      ;;
  esac
done
