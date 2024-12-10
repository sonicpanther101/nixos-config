import { studyMode, studyPaused, timeLeftStudying, studying } from "./study"
import { Gtk } from "astal/gtk3"
import { execAsync, exec, bind, Variable } from "astal"
import Battery from "gi://AstalBattery"
import Hyprland from "gi://AstalHyprland"

let isBatPresent = Battery.get_default().get_is_present()
print("isBatPresent", isBatPresent)
let StudyMode = studyMode.get() ? 'Exit Study Mode' : 'Enter Study Mode'

const monitor_scale = (monitor_name: string) => {
    if (monitor_name !== "eDP-1") {
        return 1
    } else {
        return 1.9
    }
}

const hyprCommand = (command: string) => {
  execAsync(["hyprctl", "keyword", "monitor", `${Hyprland.get_default().get_focused_monitor().name},preferred,auto,${monitor_scale(Hyprland.get_default().get_focused_monitor().name)},transform,${command}`])
}

interface MenuDefinition {
  label: string;
  handler?: () => void;
  submenu?: MenuDefinition[];
  invisible?: boolean;
}

export function createMenu(definition: MenuDefinition[]) {
  const result = new Gtk.Menu();

  for (const def of definition) {
    const item = Gtk.MenuItem.new_with_label(def.label);
    def.handler && item.connect("activate", def.handler);
    def.submenu && item.set_submenu(createMenu(def.submenu));
    item.show();
    def.invisible && (item.visible = false);
    (def.handler && def.submenu) && print("won't work idiot")
    result.append(item);
  }

  result.show();

  return result;
}

export default function Menu() {

  const updateListenerOutput = Variable.derive(
    [studyMode],
    (studyMod) => {
      StudyMode = studyMod ? 'Exit Study Mode' : 'Enter Study Mode'

      return createMenu([
        {
          label: "Session",
          submenu: [
            {
              label: "Sleep",
              handler: () => {
                execAsync(["my-sleep"]);
              },
            }, {
              label: "Power Off",
              handler: () => {
                execAsync(["my-shutdown"]);
              },
            }, {
              label: "Reboot",
              handler: () => {
                execAsync(["reboot"]);
              }
            }
          ]
        }, {
          label: "Start Linewize",
          handler: () => {
            execAsync(["my-linewize"]);
          },
          invisible: !isBatPresent
        }, {
          label: StudyMode,
          handler: () => {
            studyMode.set(!studyMod)
            if (studyMod) {
              studyPaused.set(false)
              timeLeftStudying.set(31)
              studying.set(true)
            }
          }
        }, {
          label: "Rotate Screen",
          submenu: [
            {
              label: "Upright",
              handler: () => {
                hyprCommand("0")
              }
            }, {
              label: "Left Side Up",
              handler: () => {
                hyprCommand("1")
              }
            }, {
              label: "Upside Down",
              handler: () => {
                hyprCommand("2")
              }
            }, {
              label: "Right Side Up",
              handler: () => {
                hyprCommand("3")
              }
            }, {
              label: "Rotate Clockwise",
              handler: () => {
                execAsync(`bash -c "hyprctl monitors | grep 'transform' | tail -c 2"`).then((currentRotation) => hyprCommand(String((parseInt(currentRotation) + 1) % 4)));
              }
            }, {
              label: "Rotate Counter Clockwise",
              handler: () => {
                execAsync(`bash -c "hyprctl monitors | grep 'transform' | tail -c 2"`).then((currentRotation) => hyprCommand(String((parseInt(currentRotation) + 3) % 4)));
              }
            }, {
              label: "Rotate 180",
              handler: () => {
                execAsync(`bash -c "hyprctl monitors | grep 'transform' | tail -c 2"`).then((currentRotation) => hyprCommand(String((parseInt(currentRotation) + 2) % 4)));
              }
            }
          ]
        }, {
          label: "Wallpaper",
          handler: () => {
            execAsync(["ags", "toggle", "wallpaper"]);
          }
        }, {
          label: "Gemini UI",
          handler: () => {
            execAsync(["ags", "toggle", "apis"]);
          }
        }
      ]);
    }
  )

  return updateListenerOutput
}