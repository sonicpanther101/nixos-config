hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'
sleep 5
hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
