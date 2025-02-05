import { Gtk, Widget } from "astal/gtk3"
import { readFileAsync, Variable, execAsync, bind } from "astal"

interface MyEvent {
  label: string;
  year: number;
  month: number;
  day: number;
}

const events_list = Variable<MyEvent[]>([]);
const changed = Variable<boolean>(false);
let gistID = ""
let token = ""
const input = Variable("")

const refresh = <button
  className="event-refresh"
  onClicked={() => {
    readUpdate()
  }}
>
  <label label="↻" className="event-button-label" />
</button>;

const calendar = new Gtk.Calendar({
  visible: true,
  hexpand: true,
  vexpand: true,
  detail_height_rows: 5,
  showDetails: true,
})

const Entry = new Widget.Entry({
  text: bind(input),
  hexpand: true,
  canFocus: true,
  placeholderText: "Enter event",
  className: "events-entry",
  onActivate: (self: Widget.Entry) => {
    if (self.get_text() === "") {
      events_list.set(events_list.get().filter((event) => {
        if (event.year === calendar.year && event.month === calendar.month && event.day === calendar.day) {
          return false
        } else {
          return true
        }
      }))
    } else {
      events_list.set([{ label: self.get_text(), year: calendar.year, month: calendar.month, day: calendar.day }, ...events_list.get()])
      input.set("")
    }
    writeUpdate()
  },
  setup: (self) => {
    self.hook(self, "notify::text", () => {
      input.set(self.get_text());
    });
  }
})

readFileAsync(`/home/adam/.cache/astal/secrets.json`).then((secrets) => {
  let parsed = JSON.parse(secrets)
  gistID = parsed.events_gist_id
  token = parsed.token
  if (gistID === "") {
    print("event id not found in secrets.json")
    return
  } else if (token === "") {
    print("token not found in secrets.json")
    return
  }
  readUpdate()
}).catch(print)

function readUpdate() {
  execAsync(['bash', '-c', `curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${token}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/gists/${gistID}`]).then(out => {
    
    const data = JSON.parse(out)["files"]["events.json"]["content"]

    const events = JSON.parse(data)
    
    events_list.set(events)
  }).catch(print)
}

function writeUpdate() {
  print("update")

  const out = JSON.stringify(events_list.get()).replace(/{/g, '\\n{').replace(/]/g, '\\n]').replace(/"/g, "\\\"")

  execAsync(['bash', '-c', `curl -L \
    -X PATCH \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${token}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/gists/${gistID} \
    -d '{"description":"Updated Gist","files":{"events.json":{"content":"${out}"}}}'
  `]).catch(print);
}

calendar.connect("day_selected_double_click", (calendar: Gtk.Calendar) => {
  edit(calendar.year, calendar.month, calendar.day)
})

function edit(year: number, month: number, day: number) {
  Entry.grab_focus()
  events_list.set(events_list.get().filter((event) => {
    if (event.year === year && event.month === month && event.day === day) {
      input.set(event.label)
      return false
    } else {
      return true
    }
  }))
  writeUpdate()
}

const updater = Variable.derive([events_list], (events_list) => {
  print(JSON.stringify(events_list))
  calendar.set_detail_func(
    (calendar: Gtk.Calendar, year: number, month: number, day: number) => {
      const matchingEvent = events_list.filter((event) => {
        return event.year === year && event.month === month && event.day === day;
      });
      return matchingEvent.length > 0 ? matchingEvent[0].label : null;
    }
  )
})

const Events = (
  <box vertical className="events">
    {calendar}
    <box>
      {refresh}
      {Entry}
    </box>
  </box>
)

export default Events