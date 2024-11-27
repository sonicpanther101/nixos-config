import { bind, Variable } from "astal";
import { App, Astal, Gdk, Gtk, Widget } from "astal/gtk3";
import { exec, execAsync } from "astal/process";
import Pango from "gi://Pango?version=1.0";

const WINDOW_NAME = "clipboard";

const cliphist = Variable<string[]>([]);
const query = Variable<string>(" ");

const thumb_dir = "/tmp/cliphist/thumbs"
exec(`mkdir -p "${thumb_dir}"`)
let existingThumbs = exec(`ls ${thumb_dir}`)

function decodeImage(index: string) {
  if (!existingThumbs.includes(index)) {
    exec(["bash", "-c", `cliphist decode ${index} | magick - -resize 512x ${thumb_dir}/${index}.png`])
    existingThumbs += index
  }
  return `${thumb_dir}/${index}.png`;
}

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

    return cliphist.get().filter((item) => item.match(query)).map((item) => {

      const regex = /^([0-9]+)\s(\[\[\s)?binary.*(jpg|jpeg|png|bmp)/;
      const image = item.match(regex);

      if (image) {
        print(decodeImage(item.split("\t")[0]));
        item = decodeImage(item.split("\t")[0]);
      };

      return (
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
          {image ? <icon icon={item} vexpand hexpand={false} /> :
            <label
            label={item.split("\t").slice(1).join("\t")}
            xalign={0} wrap wrapMode={Pango.WrapMode.WORD_CHAR} vexpand hexpand={false}
          />}
        </button>
      )
    });
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
      hexpand={false}
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
      <box className="Clipboard" vertical hexpand={false}>
        {Entry}
        <scrollable hscroll={Gtk.PolicyType.NEVER} hexpand={false}>
          <box className="Clipboard-Item" vertical spacing={5} vexpand hexpand={false}>
            {Items}
          </box>
        </scrollable>
      </box>
    </window>
  );
}