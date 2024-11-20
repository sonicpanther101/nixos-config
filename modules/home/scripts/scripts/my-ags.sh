pkill gjs
pkill -f ags-client

log=false
while getopts "l" option; do
    case $option in
        l)
            log=true;;
        \?)
            echo "Error: Invalid option"
            exit 1;;
    esac
done

if $log; then
    hyprctl dispatch exec "[workspace 20 silent] kitty --title ags-client --hold sh -c 'ags run /home/adam/nixos-config/modules/home/ags/new\ ags'"
else
    ags run /home/adam/nixos-config/modules/home/ags/new\ ags&
    sleep 1
    pkill .ags-wrapped
    exit
fi