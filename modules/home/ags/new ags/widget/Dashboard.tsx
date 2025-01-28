import { App, Astal, Gdk, Gtk } from "astal/gtk4";
import { Variable, bind } from "astal";
import Home from "./components/dashboard/home";
import Tasks from "./components/dashboard/tasks";
import Study from "./components/dashboard/study";
import Journal from "./components/dashboard/journal";
import Budget from "./components/dashboard/budget";
import Events from "./components/dashboard/events";
import Goals from "./components/dashboard/goals";
import Life from "./components/dashboard/life";

const WINDOW_NAME = "dashboard";
const MENU_ITEMS = ["Home", "Tasks", "Study", "Journal", "Budget", "Events", "Goals", "Life"]
const currentDisplay = Variable('Home')
const COMPONENT_MAP: { [key: string]: Gtk.Widget } = {
  Home: Home,
  Tasks: Tasks,
  Study: Study,
  Journal: Journal,
  Budget: Budget,
  Events: Events,
  Goals: Goals,
  Life: Life,
};

export default function Dashboard() {
  return (
    <window
      name={WINDOW_NAME}
      className={WINDOW_NAME}
      application={App}
      visible={false}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.BOTTOM}
      keymode={Astal.Keymode.ON_DEMAND}
      layer={Astal.Layer.OVERLAY}
      onKeyPressEvent={(self, event) => {
        if (event.get_keyval()[1] === Gdk.KEY_Escape) {
          if (self.visible) {
            self.visible = false;
          }
        }
      }}
    >
      <box className={WINDOW_NAME}>
        <box className={"menu"} vertical>
          <label label={"Adam's Dashboard"} />
          {MENU_ITEMS.map((item) => (
            <button
              onClick={() => currentDisplay.set(item)}
            >
              <label label={item} />
            </button>
          ))}
        </box>
        <box vertical hexpand>
          {bind(currentDisplay).as((item: string) => (<label className="title" label={item} />))}
          {MENU_ITEMS.map((thing) => (
              <box visible={bind(currentDisplay).as((item: string) => thing === item)} child={COMPONENT_MAP[thing]} />
            ))
          }
        </box>
      </box>
    </window>
  )
}