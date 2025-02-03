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

host=$(hostname)

if [[ $host == "laptop" ]]; then
    workspaceNum=10
else
    workspaceNum=110
fi

if $log; then
    hyprctl dispatch exec "[workspace ${workspaceNum} silent] kitty --title ags-client --hold sh -c 'ags run /home/adam/nixos-config/modules/home/ags/ags'"
else
    ags run /home/adam/nixos-config/modules/home/ags/ags&
    sleep 1
    pkill .ags-wrapped
    exit
fi