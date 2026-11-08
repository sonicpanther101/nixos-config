#!/usr/bin/env bash
# my-lock [wait_seconds] - idempotent "lock the session now".
#
# `systemctl start` is a no-op when hyprlock is already running, unlike
# `restart`, which kills a live session-lock client and makes Hyprland show its
# "lockscreen app died" screen. Then wait (default 3 s, under logind's 5 s
# sleep-inhibitor limit) until Hyprland reports the session as locked, so
# callers like hypridle's before_sleep_cmd don't let the machine suspend
# before the lock is actually up.

wait_s="${1:-3}"

systemctl --user start hyprlock.service

for _ in $(seq 1 $((wait_s * 10))); do
  case "$(hyprctl locked 2>/dev/null)" in *true*) exit 0 ;; esac
  sleep 0.1
done
exit 0
