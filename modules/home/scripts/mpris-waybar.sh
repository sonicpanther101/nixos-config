#!/usr/bin/env bash
while true; do
  STATUS=$(playerctl status 2>/dev/null)
  if [ "$STATUS" = "" ]; then
    echo '{"text": "", "class": "empty"}'
    sleep 1
    continue
  fi

  TITLE=$(playerctl metadata title 2>/dev/null | cut -c1-35)
  ARTIST=$(playerctl metadata artist 2>/dev/null | cut -c1-20)
  ALBUM=$(playerctl metadata album 2>/dev/null | cut -c1-20)
  POS=$(playerctl position 2>/dev/null)
  LEN=$(playerctl metadata mpris:length 2>/dev/null)  # microseconds

  # Convert to seconds
  LEN_S=$(echo "scale=2; $LEN / 1000000" | bc 2>/dev/null)

  if [ -n "$POS" ] && [ -n "$LEN_S" ] && [ "$LEN_S" != "0" ]; then
    PCT=$(echo "scale=4; 100 * $POS / $LEN_S" | bc)
    PCT_END=$(echo "scale=4; $PCT + 10" | bc)
    GRADIENT="background: linear-gradient(90deg, rgba(100,130,255,0.35) ${PCT}%, rgba(0,0,0,0) ${PCT_END}%);"
  else
    GRADIENT=""
  fi

  if [ "$STATUS" = "Playing" ]; then
    ICON="⏸"
  else
    ICON="⏵"
  fi

  parts=()

  [[ -n "$TITLE"  ]] && parts+=("$TITLE")
  [[ -n "$ARTIST" ]] && parts+=("$ARTIST")
  [[ -n "$ALBUM"  ]] && parts+=("$ALBUM")

  OUTPUT=""
  for p in "${parts[@]}"; do
    [[ -n "$OUTPUT" ]] && OUTPUT+=" - "
    OUTPUT+="$p"
  done

  GLYPHS=(⠁ ⠉ ⠋ ⠛ ⠟ ⠿ ⡿ ⣿)

  if [ -n "$POS" ] && [ -n "$LEN_S" ] && [ "$LEN_S" != "0" ]; then
    PCT=$(echo "100 * $POS / $LEN_S" | bc -l)
    IDX=$(echo "$PCT / 12.5" | bc)
    GLYPH=${GLYPHS[$IDX]}
  else
    GLYPH=" "
  fi

  TEXT="$ICON $OUTPUT $GLYPH"
  # Escape for JSON
  TEXT=$(echo "$TEXT" | sed 's/"/\\"/g' | cut -c1-65)

  echo "{\"text\": \"$TEXT\", \"tooltip\": \"\", \"class\": \"playing\", \"alt\": \"\", \"css\": \"$GRADIENT\"}"
  sleep 1
done