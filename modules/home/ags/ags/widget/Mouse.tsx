import { App, Astal, Gdk } from "astal/gtk3";
import { bind, Variable } from "astal";

const WINDOW_NAME = "mouse-helper";

const coords = Variable<[number, number]>([0, 0]).poll(100, "hyprctl cursorpos", (out) => {
    const [x, y]: number[] = out.split(", ").map(Number);
    return [x, y];
});

coords.stopPoll()

App.connect("window-toggled", (_, window) => {
  (window.name === WINDOW_NAME) && window.visible ? coords.startPoll() : coords.stopPoll();
});

const screenWidth = Variable<number>(0);
const screenHeight = Variable<number>(0);

export default function MouseHelper() {
  <window
    name={WINDOW_NAME}
    application={App}
    visible={false}
    keymode={Astal.Keymode.NONE}
    layer={Astal.Layer.OVERLAY}
    vexpand={true}
    css="background-color: transparent;"
    onKeyPressEvent={(self, event) => {
      if (event.get_keyval()[1] === Gdk.KEY_Escape) {
        if (self.visible) {
          self.visible = false;
        }
      }
    }}
    setup={(self) => {
      print(self.get_gdkmonitor().get_display().get_screen(0).get_resolution())
    }}
  >
      <icon icon="value-increase-symbolic" css={bind(coords).as(coords => `background-color: transparent; margin-left: ${coords[0]}px; margin-top: ${coords[1]}px;`)} />
  </window>
}