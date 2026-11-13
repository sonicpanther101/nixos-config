# usage: rotate-monitor <0|1|2|3|cw|ccw|flip>
read -r mon cur scale x y < <(
  hyprctl -j monitors | jq -r \
    '.[] | select(.focused) | "\(.name) \(.transform) \((.scale*100|round)/100) \(.x) \(.y)"'
)

case "$1" in
  cw)   t=$(( (cur + 1) % 4 )) ;;
  ccw)  t=$(( (cur + 3) % 4 )) ;;
  flip) t=$(( (cur + 2) % 4 )) ;;
  *)    t="$1" ;;
esac

pos="$x"x"$y"
hyprctl eval "hl.monitor({ output = '$mon', mode = 'preferred', position = '$pos', scale = $scale, transform = $t })"
