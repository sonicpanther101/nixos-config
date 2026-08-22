#!/usr/bin/env bash

# Pick the best player to report on:
# - Prefer one that is currently "Playing"
# - Otherwise fall back to the first player in the list (e.g. Paused)
# - Otherwise empty (no players running)
get_active_player() {
  local players
  players=$(playerctl -l 2>/dev/null)
  [ -z "$players" ] && return

  local fallback=""
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    [ -z "$fallback" ] && fallback="$p"
    local st
    st=$(playerctl -p "$p" status 2>/dev/null)
    if [ "$st" = "Playing" ]; then
      echo "$p"
      return
    fi
  done <<< "$players"

  echo "$fallback"
}

CURRENT_PLAYER=""
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player"

while true; do
  # Re-check for an active player each tick, switching if needed
  ACTIVE=$(get_active_player)

  if [ -z "$ACTIVE" ]; then
    CURRENT_PLAYER=""
    sleep 1
    continue
  fi

  # If our current player has stopped playing but another one is now
  # playing, switch to it. Otherwise keep tracking the current one as
  # long as it still exists in the player list.
  if [ -z "$CURRENT_PLAYER" ]; then
    CURRENT_PLAYER="$ACTIVE"
  else
    CURRENT_STATUS=$(playerctl -p "$CURRENT_PLAYER" status 2>/dev/null)
    if [ -z "$CURRENT_STATUS" ]; then
      # current player disappeared
      CURRENT_PLAYER="$ACTIVE"
    elif [ "$CURRENT_STATUS" != "Playing" ] && [ "$ACTIVE" != "$CURRENT_PLAYER" ]; then
      # something else started playing while ours is paused/stopped
      CURRENT_PLAYER="$ACTIVE"
    fi
  fi

  PLAYER="$CURRENT_PLAYER"

  STATUS=$(playerctl -p "$PLAYER" status 2>/dev/null)
  if [ -z "$STATUS" ]; then
    CURRENT_PLAYER=""
    rm -f "$STATE_FILE"
    sleep 1
    continue
  fi

  # Publish the currently-tracked player so other waybar modules
  # (e.g. the album-art image module) can stay in sync with it.
  printf '%s\n' "$PLAYER" > "$STATE_FILE"

  TITLE=$(playerctl -p "$PLAYER" metadata title 2>/dev/null | cut -c1-35)
  ARTIST=$(playerctl -p "$PLAYER" metadata artist 2>/dev/null | cut -c1-20)
  ALBUM=$(playerctl -p "$PLAYER" metadata album 2>/dev/null | cut -c1-20)
  POS=$(playerctl -p "$PLAYER" position 2>/dev/null)
  LEN=$(playerctl -p "$PLAYER" metadata mpris:length 2>/dev/null) # microseconds

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

  TEXT=" $ICON $OUTPUT $GLYPH"
  # Escape for JSON and limit length
  TEXT=$(printf '%s' "$TEXT" | sed 's/"/\\"/g' | cut -c1-65)
  echo "$TEXT"
  sleep 1
done
