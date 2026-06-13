read LAT LON <<<"$(curl -s ipinfo.io/loc | tr ',' ' ')"
curl -s "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&hourly=temperature_2m,precipitation,precipitation_probability&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max&current=temperature_2m&timezone=auto" \
| jq -r '
  . as $d
  | ($d.current.time) as $now
  | ($d.hourly.time | to_entries | map(select(.value >= $now)) | .[0].key) as $start
  | (
      "NOW",
      "Temp: \($d.hourly.temperature_2m[$start])°C",
      "Rain chance: \($d.hourly.precipitation_probability[$start])%",
      "Rain mm: \($d.hourly.precipitation[$start]) mm",

      "",
      "HOURLY (next 12h)",
      "Time\tTemp\tRain%\tRain(mm)",
      (range($start; $start + 12) as $i
        | $d.hourly.time[$i] as $t
        | ($t | split("T")[1] | split(":")[0] | tonumber) as $h24
        | ($h24 % 12) as $h12
        | (if $h12 == 0 then 12 else $h12 end) as $h
        | (if $h24 < 12 then "AM" else "PM" end) as $ampm
        | "\($h)\($ampm)\t\($d.hourly.temperature_2m[$i])\t\($d.hourly.precipitation_probability[$i])\t\($d.hourly.precipitation[$i])"
      ),

      "",
      "7-DAY",
      "Date\tMin-Max\tRain%\tRain(mm)",
      (range(0;7) as $i
        | "\($d.daily.time[$i])\t\($d.daily.temperature_2m_min[$i])-\($d.daily.temperature_2m_max[$i])\t\($d.daily.precipitation_probability_max[$i])\t\($d.daily.precipitation_sum[$i])"
      )
    )
' | column -t -s $'\t'