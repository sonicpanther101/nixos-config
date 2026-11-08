#!/usr/bin/env bash
set -euo pipefail

jiggle() {
  wlrctl pointer move 1 1 || true
  wlrctl pointer move -1 -1 || true
}

cleanup() {
  kill "$socat_pid" "$worker_pid" 2>/dev/null || true
}
trap cleanup EXIT TERM INT

# Any window/workspace/layer change pushes this deadline 10 s into the future.
# (This used to spawn a fresh 10-iteration jiggle loop per event, so a busy
# desktop stacked dozens of overlapping loops, each launching wlrctl twice a
# second. Now there is exactly one worker, so at most 2 wlrctl calls/second.)
deadline_file="${XDG_RUNTIME_DIR:-/tmp}/my-hyprlock-touch-click.deadline"
echo 0 > "$deadline_file"

sock="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

(
  socat -U - "UNIX-CONNECT:${sock}" | while IFS= read -r line; do
    case "$line" in
      activewindowv2*|activewindow*|openwindow*|closewindow*|openlayer*|closelayer*|workspace*)
        printf -v now '%(%s)T' -1
        echo $((now + 10)) > "$deadline_file"
        ;;
    esac
  done
) &
socat_pid=$!

# Jiggle once a second while hyprlock is up, or within 10 s of the last event.
(
  while true; do
    printf -v now '%(%s)T' -1
    deadline=$(cat "$deadline_file" 2>/dev/null || echo 0)
    if pgrep -x hyprlock >/dev/null 2>&1 || [ "$now" -lt "$deadline" ]; then
      jiggle
    fi
    sleep 1
  done
) &
worker_pid=$!

wait -n "$socat_pid" "$worker_pid"
