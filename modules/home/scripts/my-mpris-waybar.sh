#!/usr/bin/env bash

while true; do
  STATUS=$(playerctl status 2>/dev/null)

  if [ -z "$STATUS" ]; then
    sleep 1
    continue
  fi

  TITLE=$(playerctl metadata title 2>/dev/null | cut -c1-35)
  ARTIST=$(playerctl metadata artist 2>/dev/null | cut -c1-20)
  ALBUM=$(playerctl metadata album 2>/dev/null | cut -c1-20)
  POS=$(playerctl position 2>/dev/null)
  LEN=$(playerctl metadata mpris:length 2>/dev/null) # microseconds

  # Convert length to seconds
  LEN_S=$(echo "scale=2; $LEN / 1000000" | bc 2>/dev/null)

  if [ -n "$POS" ] && [ -n "$LEN_S" ] && [ "$LEN_S" != "0" ]; then
    PCT=$(echo "100 * $POS / $LEN_S" | bc -l)
  fi

  if [ "$STATUS" = "Playing" ]; then
    ICON="⏸"
  else
    ICON="⏵"
  fi

  # Build metadata list without duplicates
  parts=()

  for field in "$TITLE" "$ARTIST" "$ALBUM"; do
    [[ -z "$field" ]] && continue

    duplicate=false
    for existing in "${parts[@]}"; do
      if [[ "$field" == "$existing" ]]; then
        duplicate=true
        break
      fi
    done

    ! $duplicate && parts+=("$field")
  done

  OUTPUT=""
  for p in "${parts[@]}"; do
    [[ -n "$OUTPUT" ]] && OUTPUT+=" - "
    OUTPUT+="$p"
  done

  GLYPHS=(" " ⠁ ⠉ ⠋ ⠛ ⠟ ⠿ ⡿ ⣿)

  if [ -n "$POS" ] && [ -n "$LEN_S" ] && [ "$LEN_S" != "0" ]; then
    IDX=$(echo "$PCT / 11.11" | bc)
    (( IDX > 8 )) && IDX=8
    GLYPH=${GLYPHS[$IDX]}
  else
    GLYPH=" "
  fi

  TEXT="$ICON $OUTPUT $GLYPH"

  # Escape for JSON and limit length
  TEXT=$(printf '%s' "$TEXT" | sed 's/"/\\"/g' | cut -c1-65)

  echo "$TEXT"
  sleep 1
done