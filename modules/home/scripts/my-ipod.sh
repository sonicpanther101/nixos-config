#!/usr/bin/env bash
set -u
shopt -s nullglob

IPOD="/run/media/adam/ADAM_S IPOD"
SRC="$HOME/driveBig/IPod"
DEST="$IPOD/iPod_Control/Music/F00"
RESERVE=$((100 * 1024 * 1024))   # spare room kept free for the DB rebuild

Update() {
    cd "$IPOD" || { echo "iPod not mounted"; exit 1; }
    python3 ./3build_db.py || exit 1
    sync
}

while getopts "u" option; do
    case $option in
        u)
            Update
            exit;;
        \?)
            echo "Error: Invalid option"
            exit 1;;
    esac
done

cd "$SRC" || { echo "Can't cd to $SRC"; exit 1; }

# 1. Convert FLAC to MP3 (only delete the FLAC if the conversion worked)
for f in *.flac; do
    ffmpeg -nostdin -y -i "$f" -map_metadata 0 -c:v copy \
        -codec:a libmp3lame -qscale:a 2 "${f%.flac}.mp3" && rm -- "$f"
done

# 2. Sort new MP3s into one folder per album, named from ID3 metadata
new=(*.mp3)
if (( ${#new[@]} )); then
    exiftool -api 'Filter=s%[/\\?*:|"<>]+%-%g; s/\s+-\s+-/ -/g; s/^\s+|\s+$//g' \
        '-directory<${Band} - (${RecordingTime}) ${Album}' \
        '-filename<${Track} ${Title}.%e' \
        "${new[@]}"
fi

# 3. Copy album by album until the next one won't fit
mountpoint -q "$IPOD" || { echo "iPod not mounted"; exit 1; }
mkdir -p "$DEST"
rm -f -- "$DEST"/*

free=$(df --output=avail -B1 "$IPOD" | tail -n1)
free=$(( free - RESERVE ))
bs=$(stat -f -c %S "$IPOD")      # target cluster size

for dir in */; do
    dir=${dir%/}
    tracks=("$dir"/*.mp3)
    (( ${#tracks[@]} )) || continue

    # size on the iPod, with each file rounded up to a whole cluster
    size=$(printf '%s\0' "${tracks[@]}" | xargs -0 stat -c %s \
           | awk -v bs="$bs" '{s += int(($1 + bs - 1) / bs) * bs} END {print s + 0}')

    if (( size > free )); then
        echo "Not enough room for '$dir' ($((size/1048576)) MB needed, $((free/1048576)) MB free). Stopping."
        break
    fi

    echo "Copying: $dir"
    if cp -- "${tracks[@]}" "$DEST"/; then
        free=$(( free - size ))
    else
        echo "Copy failed for '$dir', removing partial album"
        for t in "${tracks[@]}"; do rm -f -- "$DEST/$(basename "$t")"; done
        break
    fi
done

# 4. Update iPod database
Update
