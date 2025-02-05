import { App, Astal, Gdk } from "astal/gtk3";
import { bind, execAsync, Variable } from "astal";

const WINDOW_NAME = "mouse-helper";

const coords = Variable<[number, number]>([0, 0]).poll(100, "hyprctl cursorpos", (out) => {
    const [x, y]: number[] = out.split(", ").map(Number);
    return [x, y];
});

coords.stopPoll()

App.connect("window-toggled", (_, window) => {
  (window.name === WINDOW_NAME) && window.visible ? coords.startPoll() : coords.stopPoll();
});

const screenWidth = Variable<number>(1920);
const screenHeight = Variable<number>(1080);

// execAsync(["bash", "-c", "hyprctl monitors | grep -A 11 Monitor"]).then((out) => {
//   const monitor = out.split("--").filter((line) => line.includes("focused: yes"))[0];
//   const res = monitor.split("\n")[2].split("@")[0]
//   const [x, y]: number[] = res.split("x").map(Number);
//   screenWidth.set(x);
//   screenHeight.set(y);
// }).catch(print);
      
export default function MouseHelper() {
  <window
    name={WINDOW_NAME}
    application={App}
    visible={false}
    keymode={Astal.Keymode.NONE}
    layer={Astal.Layer.OVERLAY}
    vexpand={true}
    css="background-color: transparent;"
  >
      <icon icon="value-increase-symbolic" css={bind(coords).as(coords => `background-color: transparent; margin-left: ${coords[0] - screenWidth.get() / 2}px; margin-top: ${coords[1] - screenHeight.get() / 2}px;`)} />
  </window>
}