#!/usr/bin/env bash
#
# Maintains one symlink per external USB drive currently mounted under
# /run/media/$USER (via udisks2/udiskie): ~/driveUSB for the first,
# ~/driveUSB2, ~/driveUSB3, etc. for any others plugged in at the same
# time. Each symlink is removed the moment its drive is unmounted, so
# nothing lingers in $HOME once you're done with a drive.
#
# A drive keeps its assigned slot for as long as it stays mounted, even if
# an earlier-numbered drive is unplugged first; freed slots are reused by
# the next drive that shows up, rather than renumbering everything.
#
# Internal drives are ignored. Rather than parsing a specific
# hardware-configuration.nix (which one depends on which host this runs
# on), this reads /etc/fstab — the materialized result of every host's
# fileSystems.* entries — and skips any mounted directory whose
# filesystem UUID already appears there.
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

is_internal_drive() {
    local dir="$1" uuid
    uuid=$(findmnt -no UUID --target "$dir" 2>/dev/null)
    [ -n "$uuid" ] && [ -n "${KNOWN_FSTAB_UUIDS[$uuid]:-}" ]
}

update_links() {
    # Rebuild the known-internal-UUID set fresh each run in case /etc/fstab
    # changes (e.g. after a rebuild), rather than only reading it at
    # startup.
    declare -gA KNOWN_FSTAB_UUIDS=()
    local u
    while IFS= read -r u; do
        KNOWN_FSTAB_UUIDS["$u"]=1
    done < <(grep -oE '(^|[[:space:]])UUID=[0-9A-Za-z-]+' /etc/fstab 2>/dev/null \
        | sed -E 's/^[[:space:]]*UUID=//')

    local mounted=()
    local d
    while IFS= read -r -d '' d; do
        is_internal_drive "$d" && continue
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
