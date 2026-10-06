# my-weather: prints a cached wttr.in report (and refreshes it in the
# background when stale) so hyprlock's weather widget renders instantly.
#
# hyprlock calls this from each monitor via `cmd[update:...] my-weather`.
# By serving a cached value and updating in the background, we avoid both
# the initial 2-3s network fetch and the risk of two monitors triggering
# parallel curls, while still keeping data fresh every $DATA_TTL_MIN min.

CACHE_DIR="$HOME/.cache/my-weather"
DATA_CACHE="$CACHE_DIR/data.txt"
LOCK_FILE="$CACHE_DIR/refresh.lock"

mkdir -p "$CACHE_DIR"

refresh() {
    # Default text format with ANSI colours stripped and the social link line removed.
    curl -s "wttr.in?lang=en" \
        | sed -E 's/\x1b\[[0-9;]*m//g' \
        | sed 's/ ―/ -/g' \
        | grep -v 'Follow .* for wttr.in updates' \
        > "$DATA_CACHE.tmp" && mv "$DATA_CACHE.tmp" "$DATA_CACHE"
}

# Data is meaningfully different only every few hours.
DATA_TTL_MIN=240   # 4 hours

is_stale() {
    [ ! -s "$DATA_CACHE" ] || [ -n "$(find "$DATA_CACHE" -mmin +$DATA_TTL_MIN 2>/dev/null)" ]
}

if [ -s "$DATA_CACHE" ]; then
    cat "$DATA_CACHE"
    if is_stale; then
        ( flock -n 9 || exit 0; refresh ) 9> "$LOCK_FILE" &
    fi
else
    ( flock 9; refresh ) 9> "$LOCK_FILE"
    if [ -s "$DATA_CACHE" ]; then
        cat "$DATA_CACHE"
    else
        echo "Weather unavailable"
    fi
fi
