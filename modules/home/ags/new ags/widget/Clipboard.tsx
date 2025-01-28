import { bind, Variable } from "astal";
import { App, Astal, Gdk, Gtk, Widget } from "astal/gtk4";
import { exec, execAsync } from "astal/process";
import Pango from "gi://Pango?version=1.0";

const WINDOW_NAME = "clipboard";

const cliphist = Variable<string[]>([]);
const changes = Variable<string[]>([]);
const query = Variable<string>(" ");
const init = Variable<boolean>(true);

const thumb_dir = "/tmp/cliphist/thumbs"
let existingThumbs = ""

execAsync(`mkdir -p "${thumb_dir}"`).then(() => {
  execAsync(`ls ${thumb_dir}`).then((output) => {
    existingThumbs = output
  })
})

function differences<T>(list1: T[], list2: T[]): T[] {
  return list1.filter(item => !list2.includes(item));
}

function decodeImage(index: string) {
  if (!existingThumbs.includes(index)) {
    execAsync(["bash", "-c", `cliphist decode ${index} | magick - -resize 512x ${thumb_dir}/${index}.png`]).then(() => {
      existingThumbs += index
    })
  }
  return `${thumb_dir}/${index}.png`;
}

const itemWidget = (item: string, image: any) => (
  <button
  hexpand={false}
  vexpand
  visible={item.match(query.get()) != null}
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

  const Items: Variable<Gtk.Widget[]> = Variable([]);

  
  const ItemsWatcher = Variable.derive([changes], (changes) => {
    for (let item of changes.slice(0,150)) {
      itemHolder.set(item);
    }
  });

  const itemHolder = Variable("");

  const regex = /^([0-9]+)\s(\[\[\s)?binary.*(jpg|jpeg|png|bmp)/;

  const watcher = Variable.derive([itemHolder], (item) => {
    const image = item.match(regex);
      
    if (image) {
      print(decodeImage(item.split("\t")[0]));
      item = decodeImage(item.split("\t")[0]);
    };
    
    print(item);
    init.get() ? Items.set([...Items.get(), itemWidget(item, image)]) : Items.set([itemWidget(item, image), ...Items.get()]);
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
            execAsync("cliphist list").then((output) => {
              changes.set(differences(output.split("\n"), cliphist.get()));
              cliphist.set(output.split("\n"));
              init.set(false);
            })
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
            {bind(Items)}
          </box>
        </scrollable>
      </box>
    </window>
  );
}