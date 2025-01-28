import { App, Astal, Gdk, Gtk, Widget } from "astal/gtk4";
import { bind, execAsync, Variable } from "astal";
import Pango from "gi://Pango?version=1.0";

const WINDOW_NAME = "wallpaper";

const input = Variable<string>("");
const wallpaperDir = "/home/adam/Pictures/wallpapers/preview";
const wallpapers = Variable<string[]>([]);
const Items = Variable<Gtk.Widget[]>([]);

const containsQuery = (strings: string[], query: string): boolean => strings.some(str => str.includes(query));

execAsync(["bash", "-c", `ls ${wallpaperDir}`]).then((output) => {
  wallpapers.set(output.split("\n"));
  Items.set(wallpapers.get().map((item: string) => (
    <button
      className={"image"}
      visible={bind(input).as(input => item.includes(input))}
      onClick={() => {
        App.toggle_window(WINDOW_NAME);
        execAsync(["bash", "-c", `my-rwall -n ${item}`]);
      }}
    >
      <box vertical>
        <icon icon={`${wallpaperDir}/${item}`} />
        <label css={"font-size: 1rem;"} label={item.split(".")[0]} wrap wrapMode={Pango.WrapMode.WORD_CHAR} justify={Gtk.Justification.CENTER} />
      </box>
    </button>
  )));
  input.set(" ");
  input.set("");
})

export default function Wallaper() {

  const Entry = new Widget.Entry({
    text: bind(input),
    hexpand: true,
    canFocus: true,
    placeholderText: "Search",
    className: "Input",
    onActivate: () => {
      execAsync(["bash", "-c", `my-rwall -n ${wallpapers.get().filter((item: string) => item.includes(input.get()))[0]}`]);
      App.toggle_window(WINDOW_NAME);
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
      visible={false}
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
            input.set(" ");
            input.set("");
          }
        });
      }}
    >
      <box className="wallpapers" vertical>
        {Entry}
        <scrollable vexpand hscroll={Gtk.PolicyType.NEVER}>
          <box className="ItemName" vertical spacing={10}>
            {bind(Items)}
          </box>
        </scrollable>
      </box>
    </window>
  );
}