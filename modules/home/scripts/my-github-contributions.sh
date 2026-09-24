# my-github-contributions: prints the cached contributions graph instantly
# and refreshes it in the background, same pattern as my-weather.sh - the
# `gh api graphql` call is a network round-trip, and the data it returns
# (a ~3 month contribution calendar) only meaningfully changes once a day,
# so there's no reason to block hyprlock's render on it or hit the GitHub
# API more than once a day.

USER="sonicpanther101"

CACHE_DIR="$HOME/.cache/my-github-contributions"
DATA_CACHE="$CACHE_DIR/data.txt"
LOCK_FILE="$CACHE_DIR/refresh.lock"
DATA_TTL_MIN=1440   # 1 day

mkdir -p "$CACHE_DIR"

refresh() {
    gh api graphql -f query="
{
  user(login: \"$USER\") {
    contributionsCollection {
      contributionCalendar {
        weeks {
          contributionDays {
            contributionCount
          }
        }
      }
    }
  }
}" | jq -r '
  .data.user.contributionsCollection.contributionCalendar.weeks as $weeks
  | "GITHUB (last ~3 months)",
    "",
    (["Sun","Mon","Tue","Wed","Thu","Fri","Sat"] as $days
      | range(0;7) as $d
      | $days[$d] + " " +
        ($weeks
          | map(.contributionDays[$d].contributionCount)
          | map(
              if . == 0 then "·"
              elif . < 4 then "░"
              elif . < 7 then "▒"
              elif . < 10 then "▓"
              else "█" end
            )
          | join("")
        )
    )
' > "$DATA_CACHE.tmp" && mv "$DATA_CACHE.tmp" "$DATA_CACHE"
}

is_stale() {
    [ ! -s "$DATA_CACHE" ] || [ -n "$(find "$DATA_CACHE" -mmin +$DATA_TTL_MIN 2>/dev/null)" ]
}

if [ -s "$DATA_CACHE" ]; then
    # Show what we have instantly, then top up in the background (deduped
    # with flock) if it's actually due for a refresh.
    cat "$DATA_CACHE"
    if is_stale; then
        ( flock -n 9 || exit 0; refresh ) 9> "$LOCK_FILE" &
    fi
else
    # No cache yet - one-off blocking fetch, every call after this is instant.
    ( flock 9; refresh ) 9> "$LOCK_FILE"
    if [ -s "$DATA_CACHE" ]; then
        cat "$DATA_CACHE"
    else
        echo "GitHub contributions unavailable"
    fi
fi
