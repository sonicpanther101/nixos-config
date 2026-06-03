previews=$HOME/Pictures/wallpapers/preview
wallpapers=$HOME/Pictures/wallpapers
space_wallpapers=$HOME/Pictures/wallpapers/wide/space
random=$(ls $previews | shuf | head -1)

type=""
list_mode=false

if [[ "$1" == "--walker" ]]; then
    for img in "$previews"/*; do
        name=$(basename "$img")
        echo "{\"label\":\"$name\",\"icon\":\"$img\",\"exec\":\"$HOME/scripts/wallpaper.sh -n '$name'\"}"
    done
    exit 0
fi

while getopts "ln:" option; do
    case $option in
        n)
            type="$OPTARG"
            random=$(ls $previews | grep $type | shuf | head -1)
            ;;
        l)
            list_mode=true
            ;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
    esac
done

if $list_mode; then
    if [[ -n "$type" ]]; then
        ls "$previews" | grep -F "$type"
    else
        ls "$previews"
    fi
    exit 0
fi

awww query >/dev/null 2>&1 || {
    echo "Starting awww-daemon..."
    awww-daemon >/dev/null 2>&1 &
    sleep 0.5
}

echo $random

# split image
if echo $random | grep -q widevideo-; then
    random="${random%.*}"
    random="${random#widevideo-}"
    awww img -o "DP-1" --transition-type random $wallpapers/wide/left/$random.webp&
    awww img -o "HDMI-A-1" --transition-type random $wallpapers/wide/right/$random.webp
elif echo $random | grep -q wide-random_space_image; then
    random=$(ls $space_wallpapers | shuf | head -1)
    convert -crop 50%x100% $space_wallpapers/$random /tmp/output.png
    awww img -o "DP-1" --transition-type random /tmp/output-0.png&
    awww img -o "HDMI-A-1" --transition-type random /tmp/output-1.png
elif echo $random | grep -q wide-; then
    random="${random#wide-}"
    convert -crop 50%x100% $wallpapers/wide/$random /tmp/output.png
    awww img -o "DP-1" --transition-type random /tmp/output-0.png&
    awww img -o "HDMI-A-1" --transition-type random /tmp/output-1.png
else
    awww img --transition-type random $wallpapers/others/$random
fi