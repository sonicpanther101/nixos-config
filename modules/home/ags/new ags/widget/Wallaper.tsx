import { App, Astal, Gdk, Gtk, Widget } from "astal/gtk3";
import { bind, Variable } from "astal";

const WINDOW_NAME = "wallpaper";

const input = Variable<string>("");
const wallpaperDir = "/home/adam/Pictures/wallpapers/previews";


export default function Wallaper() {

  const Entry = new Widget.Entry({
    text: bind(input),
    hexpand: true,
    canFocus: true,
    placeholderText: "Search",
    className: "Input",
    onActivate: () => {
      input.set("");
    },
    setup: (self) => {
      self.hook(self, "notify::text", () => {
        input.set(self.get_text());
      });
    },
  });

  return (
    <window
      name={WINDOW_NAME}
      className={WINDOW_NAME}
      application={App}
      visible={true}
      keymode={Astal.Keymode.EXCLUSIVE}
      layer={Astal.Layer.OVERLAY}
      vexpand={true}
      onKeyPressEvent={(self, event) => {
        if (event.get_keyval()[1] === Gdk.KEY_Escape) {
          if (self.visible) {
            input.set("");
            Entry.grab_focus();
            self.visible = false;
          }
        }
      }}
      setup={(self) => {
        self.hook(self, "notify::visible", () => {
          if (!self.get_visible()) {
            input.set("");
          } else {
            Entry.grab_focus();
          }
        });
      }}
    >
      <box className="APIs" vertical>
        {Entry}
        <scrollable vexpand hscroll={Gtk.PolicyType.NEVER}>
          <box className="ItemName" vertical spacing={5}>
            {bind(Items)}
          </box>
        </scrollable>
      </box>
    </window>
  );
}