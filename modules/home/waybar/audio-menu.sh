# my-audio-menu: dynamic output-device menu for waybar's wireplumber module.
#
# Waybar loads a menu's XML once, when the module is created, so the device list
# can't be live. Instead we regenerate the XML whenever the set of output devices
# (or the default one) changes, then ask waybar to reload (SIGUSR2).
#
#   my-audio-menu gen            write the menu XML + sink state (no reload)
#   my-audio-menu watch          watch PipeWire; regenerate + reload waybar on change
#   my-audio-menu set <N>        make the Nth listed device the default output
#
# Menu actions in waybar are static, so item "sink-N" always runs `set N`, and the
# state file maps N -> the PipeWire node id that was listed at generation time.

dir="$HOME/.cache/waybar"
xml="$dir/audio-menu.xml"
state="$dir/audio-sinks.tsv"

# id <TAB> description <TAB> 1 if default else 0, sorted by name so the order is stable
list_sinks() {
  pw-dump 2>/dev/null | jq -r '
    ([.[] | select(.type=="PipeWire:Interface:Metadata")
          | .metadata[]? | select(.key=="default.audio.sink") | .value.name] | first // "") as $def
    | .[]
    | select(.type=="PipeWire:Interface:Node" and .info.props["media.class"]=="Audio/Sink")
    | [ .id,
        (.info.props["node.description"] // .info.props["node.nick"] // .info.props["node.name"]),
        (if .info.props["node.name"] == $def then "1" else "0" end) ]
    | @tsv' | sort -f -t "$(printf '\t')" -k2,2
}

xml_escape() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

item() { # id label
  cat <<ITEM
  <child>
    <object class="GtkMenuItem" id="$1">
      <property name="label">$2</property>
      <property name="visible">true</property>
    </object>
  </child>

ITEM
}

build_xml() { # reads sink rows on stdin
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<interface>'
  echo '<object class="GtkMenu" id="menu">'
  echo
  local n=0 id desc def label
  while IFS="$(printf '\t')" read -r id desc def; do
    [ -n "$id" ] || continue
    label=$(printf '%s' "$desc" | xml_escape)
    if [ "$def" = 1 ]; then label="● $label"; else label="   $label"; fi
    item "sink-$n" "$label"
    n=$((n + 1))
  done
  if [ "$n" -gt 0 ]; then
    cat <<SEP
  <child>
    <object class="GtkSeparatorMenuItem" id="audio-sep">
      <property name="visible">true</property>
    </object>
  </child>

SEP
  fi
  item pwvucontrol "Open pwvucontrol"
  echo '</object>'
  echo '</interface>'
}

gen() {
  mkdir -p "$dir"
  local rows new
  rows=$(list_sinks)
  new=$(printf '%s\n' "$rows" | build_xml)
  printf '%s\n' "$rows" > "$state"
  if [ ! -f "$xml" ] || [ "$new" != "$(cat "$xml")" ]; then
    printf '%s\n' "$new" > "$xml"
    return 0   # changed
  fi
  return 1     # unchanged
}

reload_waybar() { systemctl --user kill -s SIGUSR2 waybar.service 2>/dev/null || true; }

case "${1:-}" in
  gen)
    gen || true
    ;;
  watch)
    gen && reload_waybar
    pactl subscribe \
      | grep --line-buffered -E "'(new|remove)' on sink |'change' on server" \
      | while read -r _; do
          sleep 0.3
          gen && reload_waybar
        done
    ;;
  set)
    id=$(sed -n "$(( ${2:?usage: my-audio-menu set N} + 1 ))p" "$state" | cut -f1)
    [ -n "$id" ] && wpctl set-default "$id"
    ;;
  *)
    echo "usage: my-audio-menu {gen|watch|set N}" >&2
    exit 1
    ;;
esac
