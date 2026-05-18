previews=$HOME/Pictures/wallpapers/preview
wallpapers=$HOME/Pictures/wallpapers
space_wallpapers=$HOME/Pictures/wallpapers/wide/space
random=$(ls $previews | shuf | head -1)

while getopts "n:" option; do
    case $option in
        n)
            type="$OPTARG"
            random=$(ls $previews | grep $type | shuf | head -1)
            ;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
    esac
done

SOCKET="/run/user/1000/wayland-1-awww-daemon.sock"

if [ ! -S "$SOCKET" ]; then
    echo "Starting awww-daemon..."
    awww-daemon &
    disown
else
    echo "awww-daemon is already running."
fi

echo $random

# split image
if echo $random | grep -q widevideo-; then
    random="${random%.*}"
    random="${random#widevideo-}"
    awww img -o "DP-1" --transition-type random $wallpapers/wide/right/$random.webp&
    awww img -o "HDMI-A-1" --transition-type random $wallpapers/wide/left/$random.webp
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