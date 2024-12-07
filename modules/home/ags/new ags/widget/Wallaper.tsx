import { App, Astal, Gdk, Gtk, Widget } from "astal/gtk3";
import { bind, exec, execAsync, Variable, timeout } from "astal";
import Pango from "gi://Pango?version=1.0";

const WINDOW_NAME = "wallpaper";

const input = Variable<string>("");
const wallpaperDir = "/home/adam/Pictures/wallpapers/preview";
const wallpapers = Variable<string[]>([]);

timeout(1000, () => {
  wallpapers.set(exec(["bash", "-c", `ls ${wallpaperDir}`]).split("\n"));
});

export default function Wallaper() {

  const Entry = new Widget.Entry({
    text: bind(input),
    hexpand: true,
    canFocus: true,
    placeholderText: "Search",
    className: "Input",
    onActivate: () => {
      App.toggle_window(WINDOW_NAME);
      execAsync(["bash", "-c", `my-rwall -n ${wallpapers.get().filter((item: string) => item.includes(input.get()))[0]}`]);
      input.set("");
    },
    setup: (self) => {
      self.hook(self, "notify::text", () => {
        input.set(self.get_text());
      });
    },
  });

  const Items = input((input) => {
  
    return wallpapers.get().filter((item: string) => item.includes(input)).map((item: string) => (
      <button
        className={"image"}
        onClick={() => {
          App.toggle_window(WINDOW_NAME);
          execAsync(["bash", "-c", `my-rwall -n ${item}`]);
        }}
      >
        <box vertical>
          <icon icon={`${wallpaperDir}/${item}`} />
          <label css={"font-size: 1rem;"} label={item.split(".")[0]} wrap wrapMode={Pango.WrapMode.WORD_CHAR} justify={Gtk.Justification.CENTER}/>
        </box>
      </button>
    ))
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
            {bind(Items).as(items => items.length ?
              items.reduce((output, _, i) => {
                if (i % 2 === 0) {
                  output.push(
                    <box spacing={10}>
                      {items[i]}
                      {items[i + 1]}
                    </box>
                  );
                }
                return output;
              }, [] as Gtk.Widget[]) : (<label label="No results" css={"font-size: 1.5rem;"} />)
            )}
          </box>
        </scrollable>
      </box>
    </window>
  );
}