import { bind, execAsync, Variable,  } from "astal";
import { App, Astal, Gdk, Gtk, Widget } from "astal/gtk3";
import Apps from "gi://AstalApps";
import app from "../../../../../../../../nix/store/ii2w7wv88fjvmldn8kzz8ni20kzpkld4-astal-gjs/share/astal/gjs/gtk3/app";

const appID = "9W3X9L-JKJ7LVX6A3";
const wolframURL = "https://api.wolframalpha.com/v1/result";
const suggestURL = "https://search.brave.com/api/suggest";

const WINDOW_NAME = "app-launcher";

const apps = new Apps.Apps();

const query = Variable<string>("");

export default function AppLauncher() {
  let appData: Apps.Application[] = [];

  const Items = query((query) => {

    const itemType = () => {
      switch (query.charAt(0)) {
        case ":":
          return "maths";
        case "/":
          return "files-root";
        case "~":
          return "files-home";
        case ".":
          return "web";
        default:
          return "app";
      }
    };

    const entryText = () => {
      if (query.startsWith(":") || query.startsWith("/") || query.startsWith("~")) {
        return query.slice(1);
      }
      return query;
    };

    if (itemType() === "app") {

      appData = apps.fuzzy_query(query);
      return appData.map((app: Apps.Application) => (
        <button
          on_Clicked={() => {
            App.toggle_window(WINDOW_NAME);
            app.launch();
          }}
        >
          <box hexpand={false}>
            <icon className="AppIcon" icon={app.iconName || ""} />
            <box className="AppText" vertical valign={Gtk.Align.CENTER}>
              <label className="AppName" label={app.name} xalign={0} truncate />
              {app.description && (
                <label
                  className="AppDescription"
                  label={app.description}
                  xalign={0}
                  truncate
                />
              )}
            </box>
          </box>
        </button>
      ));
    } else if (itemType() === "maths") {
      
      const answer = () => {
        if (entryText() === "") {
          return "";
        } else if (/^[0-9\+\-\*\/\(\)]+$/.test(entryText())) {
          return eval(entryText());
        } else {
          return "No algebra support yet";
        //   const params = {
        //     input: entryText(),
        //     appid : appID
        //   };
        //   const body = new URLSearchParams(params).toString();
        //   const response = await fetch(url, {
        //     method: "POST",
        //     body,
        //     headers: {
        //       'Content-Type': 'application/x-www-form-urlencoded'
        //     }
        //   });
        //   const result = await response.json();
        //   return result;
        }
      }
      
      return answer() ? (
        <button
          on_Clicked={() => {
            App.toggle_window(WINDOW_NAME);
            execAsync(`wl-copy ${answer()}`);
          }}
        >
          <label label={`${answer()}`} />
        </button>
      ) : (<box />);
    } else if (itemType() === "files-home" || itemType() === "files-root") {

      const items = execAsync(`ls ${entryText()}`)

      return (
        <button
          on_Clicked={() => {
            App.toggle_window(WINDOW_NAME);
            execAsync(["bash", "-c", `xdg-open ${query}`]);
          }}
        >
          <label label={`${entryText()}`} />
        </button>
      );
    } else if (itemType() === "web") {

      // const request = async () => {
      //   const params = {
      //     q: entryText(),
      //   };
      //   const body = new URLSearchParams(params).toString();
      //   const response = await fetch(suggestURL, {
      //     method: "POST",
      //     body,
      //     headers: {
      //       'Content-Type': 'application/x-www-form-urlencoded'
      //     }
      //   });
      //   const result = await response.json();
      //   return result;
      // }

      return (
        <button
          on_Clicked={() => {
            App.toggle_window(WINDOW_NAME);
            execAsync(`xdg-open ${suggestURL}?${new URLSearchParams({q: entryText()}).toString()}`);
          }}
        >
          <label label={`${entryText()}`} />
        </button>
      );
    }
  });

  const Entry = new Widget.Entry({
    text: bind(query),
    hexpand: true,
    canFocus: true,
    placeholderText: "Search",
    className: "Input",
    // primaryIconName: "edit-find",
    onActivate: () => {
      appData[0]?.launch();
      App.toggle_window(WINDOW_NAME);
    },
    setup: (self) => {
      self.hook(self, "notify::text", () => {
        query.set(self.get_text());
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
            query.set("");
            Entry.grab_focus();
            self.visible = false;
          }
        }
      }}
      setup={(self) => {
        self.hook(self, "notify::visible", () => {
          if (!self.get_visible()) {
            query.set("");
            // TODO: reset scroll
          } else {
            Entry.grab_focus();
          }
        });
      }}
    >
      <box className="AppLauncher" vertical>
        {Entry}
        <scrollable vexpand>
          <box className="ItemName" vertical spacing={5}>
            {Items}
          </box>
        </scrollable>
      </box>
    </window>
  );
}