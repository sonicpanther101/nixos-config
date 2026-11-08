#!/usr/bin/env bash
# my-dpms {off|on} - crash-hardened screen blanking for Hyprland 0.55+ (Lua).
#
# Replaces `hyprctl dispatch 'hl.dsp.dpms(...)'` in hypridle, which is what was
# taking Hyprland down. What it does differently, and why:
#
#  1. Deferred dispatch. Hyprland's wiki says dpms must not be dispatched
#     directly ("might cause undefined behavior") and shows the safe form:
#     fire it from an hl.timer. We do exactly that through `hyprctl eval`.
#  2. One output at a time, 400 ms apart, so two monitors are never modeset in
#     the same compositor tick.
#  3. Only outputs matching MY_DPMS_ALLOW are blanked (default: internal
#     panels). Many external monitors deep-sleep when blanked, drop their
#     connector and re-announce it seconds later; Hyprland 0.56/0.57 handle
#     that badly (monitor removed + re-added, DPMS silently undone, crashes on
#     DP sinks / NVIDIA: hyprwm/Hyprland#16855, #12884, omarchy#17045).
#     To include external monitors: MY_DPMS_ALLOW='.*' my-dpms off
#  4. Never blanks within ~1.5 s of hyprlock coming up. DPMS straight after the
#     lock surface appears is the sequence behind the 0.57.0 crash reports.
#  5. Circuit breaker. If Hyprland died while the screens were blanked, this
#     helper disables itself (so it costs you one session, not one per idle
#     period) until ~/.local/state/my-dpms/tripped is deleted.

set -u

ALLOW_RE="${MY_DPMS_ALLOW:-^(eDP|LVDS|DSI)-}"
FIRST_MS=500     # delay before the first output is touched
STAGGER_MS=400   # extra delay for each further output

action="${1:-}"
case "$action" in
  off|on) ;;
  *) echo "usage: my-dpms {off|on}" >&2; exit 2 ;;
esac

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/my-dpms"
tripped="$state_dir/tripped"
inflight="$state_dir/inflight"
instance="${HYPRLAND_INSTANCE_SIGNATURE:-unknown}"
mkdir -p "$state_dir"

log() { logger -t my-dpms -- "$*" 2>/dev/null || true; }

# Run one hl.timer per output so they fire staggered. $1 = enable|disable.
dispatch() {
  local act="$1" lua="" delay="$FIRST_MS" name out
  shift
  for name in "$@"; do
    lua+="hl.timer(function() hl.dispatch(hl.dsp.dpms({ action = \"$act\", monitor = \"$name\" })) end, { timeout = $delay, type = \"oneshot\" }); "
    delay=$((delay + STAGGER_MS))
  done
  out="$(hyprctl eval "$lua" 2>&1)" || true
  [ "$out" = "ok" ] || log "hyprctl eval returned: $out"
  # How long until the last timer has fired, in whole seconds (rounded up).
  echo $(( (delay + 999) / 1000 ))
}

# Output names are interpolated into Lua, so refuse anything unexpected.
safe_names() { grep -E '^[A-Za-z0-9._:+-]+$' || true; }

monitors="$(hyprctl monitors -j 2>/dev/null)" || exit 0
[ -n "$monitors" ] || exit 0

case "$action" in
  off)
    if [ -e "$tripped" ]; then
      log "disabled: $tripped exists (Hyprland died while blanked); delete it to re-enable"
      exit 0
    fi

    # Previous inflight marker from a different Hyprland instance => that
    # instance died while we had the screens blanked. Trip the breaker.
    if [ -e "$inflight" ] && [ "$(cat "$inflight" 2>/dev/null)" != "$instance" ]; then
      : > "$tripped"
      log "Hyprland exited while screens were blanked; disabling my-dpms"
      notify-send -u critical "my-dpms disabled" \
        "Hyprland exited while the screen was blanked. Screen-off is disabled until ~/.local/state/my-dpms/tripped is deleted." \
        2>/dev/null || true
      exit 0
    fi

    # If hyprlock is up, wait for the compositor to report the lock and let it settle.
    if pgrep -x hyprlock >/dev/null 2>&1; then
      for _ in $(seq 1 30); do
        case "$(hyprctl locked 2>/dev/null)" in *true*) break ;; esac
        sleep 0.2
      done
      sleep 1.5
      monitors="$(hyprctl monitors -j 2>/dev/null)" || exit 0
    fi

    mapfile -t names < <(
      printf '%s' "$monitors" \
        | jq -r --arg re "$ALLOW_RE" '.[] | select(.dpmsStatus == true) | select(.name | test($re)) | .name' \
        | safe_names
    )
    [ "${#names[@]}" -gt 0 ] || exit 0

    printf '%s' "$instance" > "$inflight"
    dispatch disable "${names[@]}" >/dev/null
    ;;

  on)
    mapfile -t names < <(
      printf '%s' "$monitors" \
        | jq -r '.[] | select(.dpmsStatus == false) | .name' \
        | safe_names
    )
    [ "${#names[@]}" -gt 0 ] || { rm -f "$inflight"; exit 0; }

    wait_s="$(dispatch enable "${names[@]}")"

    # Only clear the inflight marker once the wake-up has demonstrably survived:
    # the crash reports are "immediate on wake", so if Hyprland dies here the
    # marker stays behind and the next instance trips the breaker.
    sleep "$((wait_s + 1))"
    if [ "$(hyprctl monitors -j 2>/dev/null | jq 'all(.[]; .dpmsStatus == true)' 2>/dev/null)" = "true" ]; then
      rm -f "$inflight"
    fi
    ;;
esac
