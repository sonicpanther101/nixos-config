import { bind, Variable } from "astal";
import { App, Astal, Gdk, Gtk, Widget } from "astal/gtk3";
import { exec, execAsync } from "astal/process";

const WINDOW_NAME = "clipboard";

const cliphist = Variable<string[]>([]);
const query = Variable<string>(" ");

export default function Clipboard() {
  const Entry = new Widget.Entry({
    text: bind(query),
    hexpand: true,
    canFocus: true,
    placeholderText: "Search",
    className: "Input",
    onActivate: () => {
      App.toggle_window(WINDOW_NAME);
    },
    setup: (self) => {
      self.hook(self, "notify::text", () => {
        query.set(self.get_text());
      });
    },
  });

  const Items = query((query) => {

    return cliphist.get().filter((item) => item.match(query)).map((item) => (
      <button
        hexpand={false}
        vexpand
        on_Clicked={() => {
          execAsync([
            "sh",
            "-c",
            `cliphist decode ${(item.match("[0-9]+") ?? [""])[0]} | wl-copy`,
          ]);
          App.toggle_window(WINDOW_NAME);
        }}
      >
        <label
          label={item.split("	").slice(1).join("	")}
          xalign={0} wrap truncate vexpand hexpand={false} 
        />
      </button>
    ));
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
            query.set(" ");
            Entry.grab_focus();
            self.visible = false;
          }
        }
      }}
      setup={(self) => {
        self.hook(self, "notify::visible", () => {
          if (!self.get_visible()) {
            query.set(" ");
          } else {
            cliphist.set(exec("cliphist list").split("\n"));
            query.set("");
            Entry.grab_focus();
          }
        });
      }}
    >
      <box className="Clipboard" vertical>
        {Entry}
        <scrollable hscroll={Gtk.PolicyType.NEVER}>
          <box className="Clipboard-Item" vertical spacing={5} hexpand={false}>
            {Items}
          </box>
        </scrollable>
      </box>
    </window>
  );
}