import { App, Astal } from "astal/gtk3";

const WINDOW_NAME = "mouse-helper";

export default function MouseHelper() {
  <window
    name={WINDOW_NAME}
    className={WINDOW_NAME}
    application={App}
    visible={false}
    keymode={Astal.Keymode.NONE}
    layer={Astal.Layer.OVERLAY}
    vexpand={true}
  >
      <icon icon="value-increase-symbolic" />
  </window>
}