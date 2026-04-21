pomodoro() {
  duration=$1
  label="$2"
  L=$3
  M=$4
  leaves="$5"
  colors="$6"

  # 🧠 Estimate steps (empirical, works well enough)
  steps=$((L * 10))
  t=$(awk "BEGIN {print $duration / $steps}")

  # 🌿 Start tree WITHOUT clearing screen
  cbonsai -l -L "$L" -t "$t" -M "$M" -c "$leaves" -k "$colors" -m "$label" &
  PID=$!

  # ⏳ Countdown pinned top-right-ish
  for ((i=duration; i>0; i--)); do
    mins=$((i / 60))
    secs=$((i % 60))
    tput cup 0 50
    printf "⏳ %02d:%02d " "$mins" "$secs"
    sleep 1
  done

  kill $PID 2>/dev/null
  wait $PID 2>/dev/null

  tput cup 1 50
  echo "✔ Done"
}

run_pomodoro() {
  cycle=0

  # ☕ Break (neutral style)
  pomodoro 300 "☕ Break" 40 2 "*.,+" "22,94,34,136"

  while true; do
    case $((cycle % 4)) in
      0) # 🌸 Spring
        pomodoro 1500 "🌸 Spring Focus" 70 3 "*,.,+" "151,181,218,224"
        ;;
      1) # 🌿 Summer
        pomodoro 1500 "🌿 Summer Focus" 80 4 "&,@,$" "46,28,82,130"
        ;;
      2) # 🍂 Autumn
        pomodoro 1500 "🍂 Autumn Focus" 65 3 "%,#,@" "166,94,214,136"
        ;;
      3) # ❄️ Winter
        pomodoro 1500 "❄️ Winter Focus" 60 2 ".,\`" "250,240,255,245"
        ;;
    esac

    ((cycle++))
  done
}

run_pomodoro
