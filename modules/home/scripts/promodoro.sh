#!/usr/bin/env bash

# Hide cursor for cleaner look
tput civis
trap "tput cnorm" EXIT

notify() {
  title="$1"
  body="$2"
  type="$3"

  notify-send "$title" "$body"

  if [ "$type" = "focus" ]; then
    play -n synth 0.18 sine 660 fade h 0.01 0.18 0.05 : \
             synth 0.28 sine 880 fade h 0.01 0.28 0.1 gain -8 &
  else
    play -n synth 0.15 sine 880 fade h 0.01 0.15 0.05 : \
             synth 0.25 sine 1320 fade h 0.01 0.25 0.1 gain -6 &
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
    sleep 1 
  done 
  
  kill $PID 2>/dev/null 
  wait $PID 2>/dev/null 
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

    pomodoro 1500 "$label" 60 2 "$colors"

    notify "Pomodoro" "Focus finished ✔" focus
  
    # ☕ Break logic
    if (( cycle % 4 == 0 )); then
      break_time=900
      break_label="☕ Long Break (15 min)"
      break_colors="22,94,34,136"
    else
      break_time=300
      break_label="☕ Break (5 min)"
      break_colors="22,94,34,136"
    fi

    pomodoro "$break_time" "$break_label" 40 2 "$break_colors"

    notify "Pomodoro" "Break finished ☕" break

    ((cycle++))
  done
}

run_pomodoro