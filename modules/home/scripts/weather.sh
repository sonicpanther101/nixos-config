curl -s "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&hourly=temperature_2m,precipitation,precipitation_probability&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max&timezone=auto" \
| jq -r '
  "NOW",
  "Temp: \(.hourly.temperature_2m[0])°C",
  "Rain chance: \(.hourly.precipitation_probability[0])%",
  "Rain mm: \(.hourly.precipitation[0]) mm",

  "",
  "HOURLY (next 12h)",
  "Time\tTemp\tRain%\tRain(mm)",
  (range(0;12) as $i
    | .hourly.time[$i] as $t
    | ($t | split("T")[1] | split(":")[0] | tonumber) as $h24
    | ($h24 % 12) as $h12
    | (if $h12 == 0 then 12 else $h12 end) as $h
    | (if $h24 < 12 then "AM" else "PM" end) as $ampm
    | "\($h)\($ampm)\t\(.hourly.temperature_2m[$i])\t\(.hourly.precipitation_probability[$i])\t\(.hourly.precipitation[$i])"
  ),

  "",
  "7-DAY",
  "Date\tMin-Max\tRain%\tRain(mm)",
  (range(0;7) as $i
    | "\(.daily.time[$i])\t\(.daily.temperature_2m_min[$i])-\(.daily.temperature_2m_max[$i])\t\(.daily.precipitation_probability_max[$i])\t\(.daily.precipitation_sum[$i])"
  )
' | column -t -s $'\t'