# my-weather: prints the cached weather report immediately (if we have one)
# and refreshes the cache in the background, instead of blocking on two
# network round-trips (ipinfo.io + open-meteo) every time it's called.
#
# Why: hyprlock has one of these widgets per monitor, both calling
# `cmd[update:...] my-weather` on their own, so a live fetch could take
# 2+ seconds *and* run twice in parallel. That was blocking hyprlock's
# first render on whichever monitor drew its weather label last, which is
# what made the other monitor's clock feel like it was waiting on the
# weather. Serving a cached value first (falling back to a synchronous
# fetch only on the very first-ever run, when there's no cache yet) fixes
# that while keeping the data fresh. Weather only meaningfully changes
# every few hours, so the cache is only actually refreshed every
# $DATA_TTL_MIN minutes (see below) - hyprlock also only calls this every
# 4 hours, this is just a second line of defence if something else calls
# it more often.

CACHE_DIR="$HOME/.cache/my-weather"
DATA_CACHE="$CACHE_DIR/data.txt"
LOC_CACHE="$CACHE_DIR/location.txt"
LOCK_FILE="$CACHE_DIR/refresh.lock"

mkdir -p "$CACHE_DIR"

fetch_location() {
    # Location barely changes, so only re-resolve it once a day instead of
    # hitting ipinfo.io on every single refresh.
    if [ ! -s "$LOC_CACHE" ] || [ -n "$(find "$LOC_CACHE" -mmin +1440 2>/dev/null)" ]; then
        curl -s ipinfo.io/loc | tr ',' ' ' > "$LOC_CACHE.tmp" && mv "$LOC_CACHE.tmp" "$LOC_CACHE"
    fi
}

refresh() {
    fetch_location
    read -r LAT LON < "$LOC_CACHE"
    [ -z "$LAT" ] && return 1

    curl -s "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&hourly=temperature_2m,precipitation,precipitation_probability&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max&current=temperature_2m&timezone=auto" \
    | jq -r '
      . as $d
      | ($d.current.time) as $now
      | ($d.hourly.time | to_entries | map(select(.value >= $now)) | .[0].key) as $start
      | (
          "NOW",
          "Temp: \($d.hourly.temperature_2m[$start])°C",
          "Rain chance: \($d.hourly.precipitation_probability[$start])%",
          "Rain mm: \($d.hourly.precipitation[$start]) mm",

          "",
          "HOURLY (next 12h)",
          "Time\tTemp\tRain%\tRain(mm)",
          (range($start; $start + 12) as $i
            | $d.hourly.time[$i] as $t
            | ($t | split("T")[1] | split(":")[0] | tonumber) as $h24
            | ($h24 % 12) as $h12
            | (if $h12 == 0 then 12 else $h12 end) as $h
            | (if $h24 < 12 then "AM" else "PM" end) as $ampm
            | "\($h)\($ampm)\t\($d.hourly.temperature_2m[$i])\t\($d.hourly.precipitation_probability[$i])\t\($d.hourly.precipitation[$i])"
          ),

          "",
          "7-DAY",
          "Date\tMin-Max\tRain%\tRain(mm)",
          (range(0;7) as $i
            | "\($d.daily.time[$i])\t\($d.daily.temperature_2m_min[$i])-\($d.daily.temperature_2m_max[$i])\t\($d.daily.precipitation_probability_max[$i])\t\($d.daily.precipitation_sum[$i])"
          )
        )
    ' | column -t -s $'\t' > "$DATA_CACHE.tmp" && mv "$DATA_CACHE.tmp" "$DATA_CACHE"
}

# Data is only meaningfully different every few hours, so don't bother
# refreshing (i.e. hitting the network) if the cache is younger than this,
# even if something calls this script more often than hyprlock does.
DATA_TTL_MIN=240   # 4 hours

is_stale() {
    [ ! -s "$DATA_CACHE" ] || [ -n "$(find "$DATA_CACHE" -mmin +$DATA_TTL_MIN 2>/dev/null)" ]
}

if [ -s "$DATA_CACHE" ]; then
    # We have something to show already: print it instantly, then top up
    # the cache in the background (deduped with flock, since both monitors'
    # widgets can call this at almost the same moment) if it's due for a
    # refresh - otherwise there's nothing to do.
    cat "$DATA_CACHE"
    if is_stale; then
        ( flock -n 9 || exit 0; refresh ) 9> "$LOCK_FILE" &
    fi
else
    # No cache yet (fresh install / cleared cache) - nothing to show, so do
    # the one-off blocking fetch. Every call after this one is instant.
    ( flock 9; refresh ) 9> "$LOCK_FILE"
    if [ -s "$DATA_CACHE" ]; then
        cat "$DATA_CACHE"
    else
        echo "Weather unavailable"
    fi
fi

