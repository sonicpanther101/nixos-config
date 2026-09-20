#!/usr/bin/env bash
set -euo pipefail

jiggle() {
  wlrctl pointer move 1 1 || true
  wlrctl pointer move -1 -1 || true
}

cleanup() {
  kill "$socat_pid" "$lockpoll_pid" 2>/dev/null || true
}
trap cleanup EXIT TERM INT

# After any window/workspace/layer change, jiggle once a second for 10s
# to catch whatever opens as a follow-on (submenus, waybar popups, etc).
burst() {
  for _ in $(seq 1 10); do
    jiggle
    sleep 1
  done
}

sock="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

(
  socat -U - "UNIX-CONNECT:${sock}" | while IFS= read -r line; do
    case "$line" in
      activewindowv2*|activewindow*|openwindow*|closewindow*|openlayer*|closelayer*|workspace*)
        burst & disown
        ;;
    esac
  done
) &
socat_pid=$!

# While hyprlock is up, just jiggle every second, full stop.
(
  while true; do
    if pgrep -x hyprlock >/dev/null 2>&1; then
      jiggle
    fi
    sleep 1
  done
) &
lockpoll_pid=$!

wait -n "$socat_pid" "$lockpoll_pid"
