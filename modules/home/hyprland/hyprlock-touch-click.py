#!/usr/bin/env python3
# Converts touchscreen taps into a cursor move + click, for touch-only
# clients (like hyprlock) that never implement the Wayland touch protocol
# and so only ever react to real pointer clicks.
#
# This is deliberately narrow: it only turns a plain single-finger
# tap (down, then up nearby and soon after) into one click. It does not
# do drags, multi-touch, or gestures, and it assumes the touchscreen maps
# onto the first monitor `hyprctl monitors -j` reports with no rotation --
# fine for "tap the PIN buttons on the built-in screen", not a general
# touch driver.
#
# Meant to run only while hyprlock is on screen (see the paired systemd
# unit in hyprlock.nix), not as a general-purpose input daemon.
#
# Requires: python3-evdev (baked in via pkgs.writers), hyprctl, wlrctl.

import json
import subprocess
import sys
import time

from evdev import InputDevice, list_devices, ecodes

TAP_MAX_DURATION = 0.35  # seconds
TAP_MAX_MOVEMENT = 40    # raw touch-device units (not pixels)


def find_touchscreen():
    for path in list_devices():
        try:
            dev = InputDevice(path)
        except OSError:
            continue
        caps = dev.capabilities().get(ecodes.EV_ABS, [])
        abs_codes = [code for code, _ in caps]
        if (
            ecodes.ABS_MT_POSITION_X in abs_codes
            and "touchpad" not in dev.name.lower()
        ):
            return dev
    return None


def abs_range(dev, code):
    info = dict(dev.capabilities(absinfo=True)[ecodes.EV_ABS])[code]
    return info.min, info.max


def screen_size():
    out = subprocess.run(
        ["hyprctl", "monitors", "-j"], capture_output=True, text=True, check=True
    )
    monitor = json.loads(out.stdout)[0]
    return monitor["width"], monitor["height"]


def click_at(x, y):
    # Two separate calls, but hyprctl dispatches synchronously, so the
    # cursor has already moved by the time the click lands.
    subprocess.run(["hyprctl", "dispatch", "movecursor", str(x), str(y)])
    subprocess.run(["wlrctl", "pointer", "click"])


def main():
    dev = find_touchscreen()
    if dev is None:
        sys.exit("my-hyprlock-touch-click: no touchscreen device found")

    x_min, x_max = abs_range(dev, ecodes.ABS_MT_POSITION_X)
    y_min, y_max = abs_range(dev, ecodes.ABS_MT_POSITION_Y)
    screen_w, screen_h = screen_size()

    tracking = False
    have_start = False
    start_time = 0.0
    start_x = start_y = last_x = last_y = 0

    for event in dev.read_loop():
        if event.type != ecodes.EV_ABS:
            continue

        if event.code == ecodes.ABS_MT_TRACKING_ID:
            if event.value == -1:
                if tracking and have_start:
                    duration = time.time() - start_time
                    moved = max(abs(last_x - start_x), abs(last_y - start_y))
                    if (
                        duration <= TAP_MAX_DURATION
                        and moved <= TAP_MAX_MOVEMENT
                    ):
                        norm_x = (last_x - x_min) / (x_max - x_min)
                        norm_y = (last_y - y_min) / (y_max - y_min)
                        click_at(
                            round(norm_x * screen_w),
                            round(norm_y * screen_h),
                        )
                tracking = False
                have_start = False
            else:
                tracking = True
                have_start = False
                start_time = time.time()
        elif event.code == ecodes.ABS_MT_POSITION_X:
            last_x = event.value
            if tracking and not have_start:
                start_x = event.value
        elif event.code == ecodes.ABS_MT_POSITION_Y:
            last_y = event.value
            if tracking and not have_start:
                start_y = event.value
                have_start = True


if __name__ == "__main__":
    main()
