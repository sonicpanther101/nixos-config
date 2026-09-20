set -euo pipefail

jiggle() {
  wlrctl pointer move 1 1 || true
  wlrctl pointer move -1 -1 || true
}

# Find the touchscreen device libinput knows about.
touch_dev="$(libinput list-devices \
  | awk '/^Device:/{name=$0} /Capabilities:.*touch/{print name; exit}' \
  | sed 's/^Device:[[:space:]]*//')"

libinput debug-events | while IFS= read -r line; do
  case "$line" in
    *"$touch_dev"*TOUCH_DOWN*)
      jiggle
      ;;
  esac
done
