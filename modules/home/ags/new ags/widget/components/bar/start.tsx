import { Gdk, Gtk, Astal, Widget, App } from "astal/gtk3"
import Menu from "./menu"

export default function StartButton() {

  const onClick: Widget.ButtonProps["onClick"] = (self: Widget.Button, e: Astal.ClickEvent) => {
    if (e.button === Gdk.BUTTON_PRIMARY) {
      self.className = App.get_window("dashboard")?.visible ? "StartButton dashboard" : "StartButton no-dashboard"
      App.toggle_window("dashboard")
    } else if (e.button === Gdk.BUTTON_SECONDARY) {
      Menu().get().popup_at_pointer(null);
    } else if (e.button === Gdk.BUTTON_MIDDLE) {
      App.toggle_window("app-launcher")
    }
  };

  return <button
    className="StartButton no-dashboard"
    onClick={onClick}>
    <label label="" />
  </button>
}