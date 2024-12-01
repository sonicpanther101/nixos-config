import { exec, execAsync, bind, Variable } from "astal";
import { App, Astal, Gdk, Gtk, Widget } from "astal/gtk3";

const WINDOW_NAME = "apis";

const input = Variable<string>("");
const APItype = Variable<"Gemini" | "ChatGPT" | "test">("Gemini");

export default function APIs() {

  const Entry = new Widget.Entry({
    text: bind(input),
    hexpand: true,
    canFocus: true,
    placeholderText: "Search",
    className: "Input",
    onActivate: () => {
      print(input.get());  
      App.toggle_window(WINDOW_NAME);
    },
    setup: (self) => {
      self.hook(self, "notify::text", () => {
        input.set(self.get_text());
      });
    },
  });

  const Items = input((input) => { 
    if (APItype.get() === "Gemini") { 
      
    } else if (APItype.get() === "ChatGPT") {

    }else if (APItype.get() === "test") {

    }
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
          }
        });
      }}
    >
      <box className="AppLauncher" vertical>
        <box>
          <button
            onClick={() => {
              APItype.set("Gemini");
            }}
          >
            <icon icon="google" />
          </button>
          <button
            onClick={() => {
              APItype.set("ChatGPT");
            }}
          >
            <icon icon="accessories-screenshot" />
          </button>
          <button
            onClick={() => {
              APItype.set("test");
            }}
          >
            <icon icon="advert-block" />
          </button>
        </box>
        <scrollable vexpand hscroll={Gtk.PolicyType.NEVER}>
          <box className="ItemName" vertical spacing={5}>
            {/* {Items} */}
          </box>
        </scrollable>
        {Entry}
      </box>
    </window>
  );
}