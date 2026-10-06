hyprctl dispatch "hl.dsp.dpms({ action = \"off\" })"
sleep 5
hyprctl dispatch "hl.dsp.dpms({ action = \"on\" })"
