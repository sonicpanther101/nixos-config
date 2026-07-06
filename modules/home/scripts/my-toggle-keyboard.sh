if pgrep -x wvkbd-mobintl > /dev/null; then
  pkill wvkbd-mobintl
else
  wvkbd-mobintl -L 250 &
fi
