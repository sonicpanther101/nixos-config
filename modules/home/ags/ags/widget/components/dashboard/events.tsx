import { Gtk } from "astal/gtk3"

const calendar = new Gtk.Calendar({
  visible: true
})

const Events = (
  <box>
    {calendar}
  </box>
)

export default Events