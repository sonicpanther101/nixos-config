import { Gdk, Astal, Widget, App } from "astal/gtk4"
import Menu from "./menu"
import { bind, Variable } from "astal";

App.connect("window-toggled", (_, window) => {
  (window.name === "dashboard") && window.visible ? startClass.set("dashboard StartButton") : startClass.set("no-dashboard StartButton")
});

const startClass = Variable<string>("no-dashboard StartButton")

export default function StartButton() {

  const onClick: Widget.ButtonProps["onClick"] = (_: Widget.Button, e: Astal.ClickEvent) => {
    if (e.button === Gdk.BUTTON_PRIMARY) {
      App.toggle_window("dashboard")
    } else if (e.button === Gdk.BUTTON_SECONDARY) {
      Menu().get().popup_at_pointer(null);
    } else if (e.button === Gdk.BUTTON_MIDDLE) {
      App.toggle_window("app-launcher")
    }
  };

  return <button
    className={bind(startClass)}
    onClick={onClick}>
    <label label="" />
  </button>
}