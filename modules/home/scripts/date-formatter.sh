#!/usr/bin/env bash

day=$(date +%e)

if ((day % 10 == 1 && day % 100 != 11)); then suf="st"
elif ((day % 10 == 2 && day % 100 != 12)); then suf="nd"
elif ((day % 10 == 3 && day % 100 != 13)); then suf="rd"
else suf="th"
fi

date +"%a $day$suf %b  %l:%M%p"