import { bind, execAsync, exec, Variable,  } from "astal";
import { App, Astal, Gdk, Gtk, Widget } from "astal/gtk3";
import Apps from "gi://AstalApps";

const appID = "9W3X9L-JKJ7LVX6A3";
const wolframURL = "https://api.wolframalpha.com/v1/result";
const suggestURL = "https://search.brave.com/api/suggest";
const searchURL = "https://search.brave.com/search";

const WINDOW_NAME = "app-launcher";

const apps = new Apps.Apps();

const query = Variable<string>("");

const itemType = Variable.derive([query], (query) => {
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
});


const entryText = Variable.derive([query], (query) => {
  if (query.startsWith(":") || query.startsWith("/") || query.startsWith("~") || query.startsWith(".")) {
    return query.slice(1);
  }
  return query;
});

const answer = Variable.derive([itemType, entryText], (itemType, entryText) => {
  if (itemType !== "maths") return "";

  if (entryText === "") {
    return "";
  } else if (/^[0-9\+\-\*\/\(\)\^]+$/.test(entryText)) {
    return eval(entryText.replace(/\^/g, "**"));
  } else {
    return exec(["bash", "-c", `curl -s "${wolframURL}?appid=${appID}&i=${encodeURIComponent(entryText)}"`]);
  }
});

const pre = Variable.derive([itemType, entryText], (itemType, entryText) => {
  if (itemType !== "files-home" && itemType !== "files-root") return "";
  return entryText.includes("/") ? `${entryText.split("/").slice(0, -1).join("/")}/` : ""
});
const search = Variable.derive([itemType, entryText], (itemType, entryText) => {
  if (itemType !== "files-home" && itemType !== "files-root") return "";
  return entryText.includes("/") ? entryText.split("/")[entryText.split("/").length - 1] : entryText;
});
const items = Variable.derive([itemType, search, pre], (itemType, search, pre) => {
  if (itemType !== "files-home" && itemType !== "files-root") return [];
  return exec(["bash", "-c", `ls ${itemType === "files-home" ? "/home/adam/" : "/"}${pre} -a | grep "${search.replace(/\./g, "\\.")}"`]).split("\n").filter(function(value, index, arr){ return value !== "." && value !== "..";});
});

export default function AppLauncher() {
  let appData: Apps.Application[] = [];

  const Items = query((query) => {

    if (itemType.get() === "app") {

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
    } else if (itemType.get() === "maths") {
      
      return answer.get() ? (
        <button
          vexpand
          on_Clicked={() => {
            App.toggle_window(WINDOW_NAME);
            execAsync(`wl-copy ${answer.get()}`);
          }}
        >
          <label vexpand wrap label={`${answer.get()}`} />
        </button>
      ) : (<box />);
    } else if (itemType.get() === "files-home" || itemType.get() === "files-root") {

      return items.get().map((item) => (
        <button
          on_Clicked={() => {
            App.toggle_window(WINDOW_NAME);
            execAsync(["bash", "-c", `xdg-open ${itemType.get() === "files-home" ? "/home/adam/" : "/"}${pre.get()}${item}`]);
          }}
        >
          <label label={`${item}`} />
        </button>
      ));
    } else if (itemType.get() === "web") {

      const suggestions = query.slice(1) ? JSON.parse(exec(["bash", "-c", `curl -s "${suggestURL}?q=${encodeURIComponent(query.slice(1))}"`])) : [];

      // adding the original query to the suggestions
      return suggestions.length ? [...new Set([query.slice(1), ...suggestions[1]])].map((suggestion: string) => (
        <button
          on_Clicked={() => {
            App.toggle_window(WINDOW_NAME);
            execAsync(`xdg-open ${searchURL}?q=${encodeURIComponent(suggestion)}`);
          }}
        >
          <label label={`${suggestion}`} />
        </button>
      )) : (<box />);
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
      switch (itemType.get()) {
        case "app":
          appData[0]?.launch();
        case "maths":
          execAsync(`wl-copy ${answer.get()}`);
        case "files-home":
          execAsync(["bash", "-c", `xdg-open /home/adam/${pre.get()}${items.get()[0]}`]);
        case "files-root":
          execAsync(["bash", "-c", `xdg-open /${pre.get()}${items.get()[0]}`]);
        case "web":
          execAsync(`xdg-open ${searchURL}?q=${query.get().slice(1).replace(/\ /g, "+")}`);
      }
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