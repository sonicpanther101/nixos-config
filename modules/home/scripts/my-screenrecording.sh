#!/usr/bin/env bash

if pgrep -x wf-recorder >/dev/null; then
    pkill -INT wf-recorder
    notify-send "Screen Recording" "Recording saved"
else
    mkdir -p "$HOME/Pictures/recordings"

    wf-recorder \
        -g "$(slurp)" \
        -c libx264 \
        -f "$HOME/Pictures/recordings/$(date +'%Y-%m-%d-At-%Hh%Mm%Ss').mp4" &

    notify-send "Screen Recording" "Recording started"
fi