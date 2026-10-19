# Toggle monitor mirroring.
#   - Nothing mirrored: the focused monitor is the source and every other
#     monitor mirrors it.
#   - Already mirrored: reload the Hyprland config, which re-applies the
#     hl.monitor({ ... }) layout from settings.nix.

MONITORS=$(hyprctl monitors -j)

if echo "$MONITORS" | jq -e 'any(.[]; (.mirrorOf // "none" | tostring) != "none")' > /dev/null; then
  hyprctl reload
  notify-send "Mirror monitor" "Mirroring off, layout restored"
  exit 0
fi

SOURCE=$(echo "$MONITORS" | jq -r '.[] | select(.focused == true) | .name')
OTHERS=$(echo "$MONITORS" | jq -r '.[] | select(.focused != true) | .name')

if [ -z "$SOURCE" ]; then
  notify-send "Mirror monitor" "Could not determine the focused monitor"
  exit 1
fi

if [ -z "$OTHERS" ]; then
  notify-send "Mirror monitor" "Only one monitor connected, nothing to mirror"
  exit 1
fi

for OUTPUT in $OTHERS; do
  hyprctl eval "hl.monitor({ output = '$OUTPUT', mode = 'preferred', position = 'auto', scale = 1, mirror = '$SOURCE' })"
done

notify-send "Mirror monitor" "Mirroring $SOURCE onto the other monitor(s)"
