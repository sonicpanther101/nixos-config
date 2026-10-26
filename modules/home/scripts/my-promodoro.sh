#!/usr/bin/env bash

# Defaults (minutes)
FOCUS_MIN=25
BREAK_MIN=5
LONG_BREAK_MIN=15
LONG_BREAK_EVERY=4

usage() {
  cat <<EOF
Usage: ${0##*/} [options]

Options:
  -f, --focus MIN        Focus session length in minutes   (default: $FOCUS_MIN)
  -b, --break MIN        Short break length in minutes     (default: $BREAK_MIN)
  -l, --long-break MIN   Long break length in minutes      (default: $LONG_BREAK_MIN)
  -n, --every N          Long break after every N focus sessions (default: $LONG_BREAK_EVERY)
  -h, --help             Show this help
EOF
}

die() {
  echo "${0##*/}: $1" >&2
  exit 1
}

# Require a positive integer
need_posint() {
  [[ "$2" =~ ^[1-9][0-9]*$ ]] || die "$1 expects a positive whole number, got '${2:-}'"
}

# Parse args before touching the terminal, so --help / errors leave it alone
while [ $# -gt 0 ]; do
  case "$1" in
    -f|--focus)       need_posint "$1" "${2:-}"; FOCUS_MIN=$2;       shift 2 ;;
    -b|--break)       need_posint "$1" "${2:-}"; BREAK_MIN=$2;       shift 2 ;;
    -l|--long-break)  need_posint "$1" "${2:-}"; LONG_BREAK_MIN=$2;  shift 2 ;;
    -n|--every)       need_posint "$1" "${2:-}"; LONG_BREAK_EVERY=$2; shift 2 ;;
    --focus=*)        need_posint "--focus" "${1#*=}";      FOCUS_MIN=${1#*=};        shift ;;
    --break=*)        need_posint "--break" "${1#*=}";      BREAK_MIN=${1#*=};        shift ;;
    --long-break=*)   need_posint "--long-break" "${1#*=}"; LONG_BREAK_MIN=${1#*=};   shift ;;
    --every=*)        need_posint "--every" "${1#*=}";      LONG_BREAK_EVERY=${1#*=}; shift ;;
    -h|--help)        usage; exit 0 ;;
    *)                usage >&2; die "unknown option '$1'" ;;
  esac
done

# Hide cursor for cleaner look
tput civis

STATUS_FILE="/tmp/pomodoro-waybar"
PID=""

cleanup() {
    trap - EXIT INT TERM
    [ -n "$PID" ] && kill "$PID" 2>/dev/null
    echo "" > "$STATUS_FILE"
    tput cnorm
}

# Ctrl+C / kill must actually exit; EXIT then runs cleanup
trap 'exit 130' INT TERM
trap cleanup EXIT

notify() {
  title="$1"
  body="$2"
  type="$3"

  notify-send "$title" "$body"

  if [ "$type" = "focus" ]; then
    play -n synth 0.18 sine 660 fade h 0.01 0.18 0.05 : \
             synth 0.28 sine 880 fade h 0.01 0.28 0.1 gain -8  2>/dev/null 
  else
    play -n synth 0.15 sine 880 fade h 0.01 0.15 0.05 : \
             synth 0.25 sine 1320 fade h 0.01 0.25 0.1 gain -6  2>/dev/null 
  fi
}

pomodoro() { 
  duration=$1 
  label="$2" 
  L=$3 M=$4 
  colors="$5" 

  # Estimate timing sync 
  steps=$((L * 12)) 
  t=$(awk "BEGIN {print $duration / $steps}") 

  cbonsai -l -L "$L" -t "$t" -M "$M" -k "$colors" -m "$label" & 
  PID=$! 

  for ((i=duration; i>0; i--)); do 
    mins=$((i / 60)) 
    secs=$((i % 60)) 
    tput cup 0 60 
    printf "⏳ %02d:%02d " "$mins" "$secs"
    printf "$(echo $label | sed 's|^❄|❄ |' | head -c 4 | sed 's| ||') %02d:%02d ⏳\n" "$mins" "$secs" > "$STATUS_FILE"
    sleep 1 
  done 
  
  kill $PID 2>/dev/null 
  wait $PID 2>/dev/null
  echo "" > "$STATUS_FILE"
}

run_pomodoro() {
  cycle=1
 
  while true; do
    # 🌸 Seasonal styles
    case $((cycle % 4)) in
      1) colors="151,181,218,224"; label="🌸 Spring Focus" ;;
      2) colors="46,28,82,130";    label="🌿 Summer Focus" ;;
      3) colors="166,94,214,136";  label="🍂 Autumn Focus" ;;
      0) colors="250,240,255,245"; label="❄️ Winter Focus" ;;
    esac

    pomodoro $((FOCUS_MIN * 60)) "$label" 60 2 "$colors"

    notify "Pomodoro" "Focus finished ✔" focus
  
    # ☕ Break logic
    if (( cycle % LONG_BREAK_EVERY == 0 )); then
      break_time=$((LONG_BREAK_MIN * 60))
      break_label="☕ Long Break ($LONG_BREAK_MIN min)"
      break_colors="22,94,34,136"
    else
      break_time=$((BREAK_MIN * 60))
      break_label="☕ Break ($BREAK_MIN min)"
      break_colors="22,94,34,136"
    fi

    pomodoro "$break_time" "$break_label" 40 2 "$break_colors"

    notify "Pomodoro" "Break finished ☕" break

    ((cycle++))
  done
}

run_pomodoro
