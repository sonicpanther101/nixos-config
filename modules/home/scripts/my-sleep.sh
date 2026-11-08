#!/usr/bin/env bash
host=$(hostname)

# Lid close can reach us twice (logind's own suspend + the Hyprland lid bind).
# If a sleep is already being prepared, don't queue a second one.
if busctl --system get-property org.freedesktop.login1 /org/freedesktop/login1 \
     org.freedesktop.login1.Manager PreparingForSleep 2>/dev/null | grep -q true; then
    exit 0
fi

if [[ $host == "desktop" ]]; then
    openrgb --mode direct --color 000000 # Turn all RGB off, without opening openrgb
fi

playerctl -p $(cat "${XDG_RUNTIME_DIR:-/tmp}/waybar-current-player") pause   # Pause current media

# Lock BEFORE suspending (idempotent, waits until Hyprland reports locked).
# The old flow started hyprlock only after resume, i.e. while outputs were
# still re-initialising, which is what upstream reports as hyprlock SIGABRT /
# "lockscreen app died". It also no longer runs `pkill hypridle`: when this
# script is started by hypridle it lives in hypridle's own cgroup, so that
# killed the script itself before it could re-lock.
my-lock

systemctl suspend                        # Blocks until the machine has resumed

# ---- resumed ----------------------------------------------------------------

# Wait until the output list has stopped changing (~1 s stable, 6 s max).
prev=""; stable=0
for _ in $(seq 1 30); do
    cur=$(hyprctl monitors -j 2>/dev/null | jq -r '[.[] | "\(.name):\(.dpmsStatus)"] | sort | join(",")' 2>/dev/null)
    if [ -n "$cur" ] && [ "$cur" = "$prev" ]; then stable=$((stable + 1)); else stable=0; fi
    prev=$cur
    [ "$stable" -ge 5 ] && break
    sleep 0.2
done

my-dpms on                               # Only acts if a screen is actually off

# If hyprlock died while the outputs were churning, bring it back (the session
# is still locked). Otherwise just nudge the pointer: Hyprland can leave a stale
# frame on the lock screen until something redraws it.
case "$(hyprctl locked 2>/dev/null)" in
    *true*) pgrep -x hyprlock >/dev/null || systemctl --user start hyprlock.service ;;
esac
wlrctl pointer move 1 1 || true
wlrctl pointer move -1 -1 || true

if [[ $host == "desktop" ]]; then
    openrgb --mode direct --color 000000 # Turn all RGB off if started on boot
fi

cd ~/nixos-config && git fetch
