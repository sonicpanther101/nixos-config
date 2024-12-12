import { Variable, bind, execAsync, readFileAsync } from "astal";

const githubStatsPath = Variable<string>("")
const githubContributionsPath = Variable<string>("")
const weather = Variable<any>([])
const windDirections = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW","N"]

function unixToDate(unix: number) {

  let dateObj = new Date(unix * 1000);

  // Create a formatter for the desired locale and options
  let options = {
    day: 'numeric',
    month: 'short',
    timeZone: 'Pacific/Auckland'
  };
  let formatter = new Intl.DateTimeFormat('en-US', options as Intl.DateTimeFormatOptions);

  return formatter.format(dateObj);
}

function unixToTime(unix: number) {

  let dateObj = new Date(unix * 1000);

  // Create a formatter for the desired locale and options
  let options = {
    hour: 'numeric',
    hour12: true,
    timeZone: 'Pacific/Auckland'
  };
  let formatter = new Intl.DateTimeFormat('en-US', options as Intl.DateTimeFormatOptions);

  return formatter.format(dateObj);
}

function splitList(list: any[]): any[][] {
  const result: any[][] = [];
  let currentSublist: any[] = [];
  let currentDay = list[0] && unixToDate(list[0].dt);

  for (const item of list) {
    if (unixToDate(item.dt) === currentDay) {
      currentSublist.push(item);
    } else {
      result.push(currentSublist);
      currentSublist = [item];
      currentDay = unixToDate(item.dt);
    }
  }

  if (currentSublist.length > 0) {
    result.push(currentSublist);
  }

  return result;
}

execAsync(["bash", "-c", `curl https://wakatime.com/badge/user/daab2500-5508-44c2-9a15-c2458e9e78d5.svg -o /tmp/wakatime.svg`]).then(() => {
  githubStatsPath.set("/tmp/wakatime.svg")
})
execAsync(["bash", "-c", `curl https://ghchart.rshah.org/764b05/sonicpanther101 | magick - -channel RGB -negate -density 5000 -resize 2000x2000 -fuzz 6% -transparent black /tmp/contributions.png`]).then(() => {
  githubContributionsPath.set("/tmp/contributions.png")
})
readFileAsync("/home/adam/.cache/astal/secrets.json").then((data) => {
  let parsed = JSON.parse(data)
  execAsync(["bash", "-c", `curl "https://api.openweathermap.org/data/2.5/forecast?lat=${parsed.lat}&lon=${parsed.lon}&appid=${parsed.openWeather}&units=metric"`]).then((data) => {
    weather.set(JSON.parse(data).list)
  })
}).catch(print)

export default function Home() {
  return (
    <centerbox className="home">
      <box hexpand/>
      <box vertical>
        <icon icon={bind(githubStatsPath)} css={"font-size: 200px;margin: 20px 0px;"} />
        <icon icon={bind(githubContributionsPath)} css={"font-size: 1000px;"} />
        <box vertical className="weather" homogeneous>
          {bind(weather).as(w => (
            w && splitList(w).map((list: any[]) => (
              <box>
                <label label={unixToDate(list[0].dt)} />
                {list.map((item: any) => (
                  <box vertical className="day">
                    <icon icon={`/home/adam/.cache/ags/icons/${item.weather[0].icon}.png`} />
                    <label label={`${unixToTime(item.dt)} | ${Math.round(item.main.temp)}°C`} />
                    <label label={`${Math.round(item.wind.speed * 19.438444924)/10}-${Math.round(item.wind.gust * 19.438444924)/10}kn ${windDirections[Math.round((item.wind.deg % 360) / 22.5)]}`} />
                    <label label={item.weather[0].description.split(" ").map((word: string) => word.charAt(0).toUpperCase() + word.slice(1)).join(" ")} />
                  </box>
                ))}
              </box>
            ))
          ))}
        </box>
      </box>
      <box hexpand/>
    </centerbox>
  )
}