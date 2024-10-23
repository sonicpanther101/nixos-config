command='bottles-cli run -e "/home/adam/.local/share/bottles/bottles/School/drive_c/Program Files (x86)/FamilyZone/MobileZoneAgent/bin/fc-system-service_windows-amd64.exe" -b School'

hyprctl dispatch exec "[workspace 7 silent] kitty  --title linewize --hold sh -c '${command}'"