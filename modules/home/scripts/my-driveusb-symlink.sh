#!/usr/bin/env bash
#
# Maintains one symlink per USB drive currently mounted under
# /run/media/$USER (via udisks2/udiskie): ~/driveUSB for the first,
# ~/driveUSB2, ~/driveUSB3, etc. for any others plugged in at the same
# time. Each symlink is removed the moment its drive is unmounted, so
# nothing lingers in $HOME once you're done with a drive.
#
# A drive keeps its assigned slot for as long as it stays mounted, even if
# an earlier-numbered drive is unplugged first; freed slots are reused by
# the next drive that shows up, rather than renumbering everything.
#
set -uo pipefail

WATCH_DIR="/run/media/$(basename "$HOME")"
MAX_SLOTS=20 # generous ceiling, just to bound the search loops below

link_name() {
    local n="$1"
    if [ "$n" -eq 1 ]; then
        echo "$HOME/driveUSB"
    else
        echo "$HOME/driveUSB${n}"
    fi
}

update_links() {
    local mounted=()
    while IFS= read -r -d '' d; do
        mounted+=("$d")
    done < <(find "$WATCH_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

    declare -A still_mounted
    for d in "${mounted[@]}"; do
        still_mounted["$d"]=1
    done

    # Drop symlinks (that we manage) whose drive is no longer mounted, and
    # note which mounted drives already have a symlink pointing at them.
    declare -A already_linked
    local n link target
    for ((n = 1; n <= MAX_SLOTS; n++)); do
        link=$(link_name "$n")
        if [ -L "$link" ]; then
            target=$(readlink -f "$link")
            if [ -n "${still_mounted[$target]:-}" ]; then
                already_linked["$target"]=1
            else
                rm -f "$link"
            fi
        fi
    done

    # Give any newly-mounted drive the lowest free slot. Real files/dirs
    # that happen to occupy a driveUSB* name (not symlinks we made) are
    # left untouched.
    for d in "${mounted[@]}"; do
        [ -n "${already_linked[$d]:-}" ] && continue
        for ((n = 1; n <= MAX_SLOTS; n++)); do
            link=$(link_name "$n")
            if [ ! -e "$link" ] && [ ! -L "$link" ]; then
                ln -sfn "$d" "$link"
                break
            fi
        done
    done
}

# /run/media/$USER doesn't exist until udisks2 mounts something for the
# first time after boot, so wait for it rather than erroring out.
while [ ! -d "$WATCH_DIR" ]; do
    sleep 2
done

update_links

# React to drives being mounted/unmounted for the rest of the session.
inotifywait -m -e create -e moved_to -e delete -e moved_from --format '%f' "$WATCH_DIR" \
| while read -r _; do
    update_links
done
