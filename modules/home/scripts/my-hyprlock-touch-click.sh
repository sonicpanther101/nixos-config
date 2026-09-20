jiggle() {
  wlrctl pointer move 1 1 || true
  wlrctl pointer move -1 -1 || true
}

cleanup() {
  jobs -p | xargs -r kill 2>/dev/null || true
}
trap cleanup EXIT TERM INT

touch_dev="$(libinput list-devices \
  | awk '/^Device:/{name=$0} /Capabilities:.*touch/{print name; exit}' \
  | sed 's/^Device:[[:space:]]*//')"

# Listener 1: raw touch-down, catches taps on anything including submenus.
libinput debug-events | while IFS= read -r line; do
  case "$line" in
    *"$touch_dev"*TOUCH_DOWN*) jiggle ;;
  esac
done &

# Listener 2: Hyprland state changes not tied to a touch at all.
sock="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
socat -U - "UNIX-CONNECT:${sock}" | while IFS= read -r line; do
  case "$line" in
    activewindowv2*|activewindow*|openwindow*|closewindow*|openlayer*|closelayer*)
      jiggle
      ;;
  esac
done &

wait -n
