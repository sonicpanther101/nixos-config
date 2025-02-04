import { Gtk } from "astal/gtk3"

const calendar = new Gtk.Calendar({
  visible: true,
  hexpand: true,
  vexpand: true,
  detail_height_rows: 5,
  showDetails: true,
})

calendar.set_detail_func(
  (calendar: Gtk.Calendar, year: number, month: number, day: number) => {
    return "test"
  }
)

calendar.connect("day_selected_double_click", (calendar: Gtk.Calendar) => {
  console.log(calendar.year, calendar.month, calendar.day)
})

const Events = (
  <box>
    {calendar}
  </box>
)

export default Events