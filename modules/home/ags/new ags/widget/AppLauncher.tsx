import { bind, execAsync, exec, Variable,  } from "astal";
import { App, Astal, Gdk, Gtk, Widget } from "astal/gtk3";
import Apps from "gi://AstalApps";

const appID = "9W3X9L-P93G6KHG74";
const wolframURL = "https://api.wolframalpha.com/v2/result";
const wolframURLFull = "https://api.wolframalpha.com/v2/query";
const suggestURL = "https://search.brave.com/api/suggest";
const searchURL = "https://search.brave.com/search";

const WINDOW_NAME = "app-launcher";

const apps = new Apps.Apps();

const query = Variable<string>("");

const itemType = Variable.derive([query], (query) => {
  switch (query.charAt(0)) {
    case ":": return "maths-complex-full";
    case ";": return "maths-complex";
    case "0": case "1": case "2": case "3": case "4": case "5": case "6": case "7": case "8": case "9": return "maths";
    case "/": return "files-root";
    case "~": return "files-home";
    case "?": return "web";
    default: return "app";
  }
});


const entryText = Variable.derive([query], (query) => {
  if (query.startsWith(":") || query.startsWith(";") || query.startsWith("/") || query.startsWith("~") || query.startsWith("?")) {
    return query.slice(1);
  }
  return query;
});

const answer: any = Variable("");
const answerWatcher = Variable.derive([itemType, entryText], (itemType, entryText) => {
  if (itemType !== "maths" && itemType !== "maths-complex" && itemType !== "maths-complex-full") return "";

  if (entryText === "") {
    answer.set("");
  } else if (itemType === "maths" && /^[0-9\+\-\*\/\(\)\^]+$/.test(entryText)) {
    answer.set((0, eval)(entryText.replace(/\^/g, "**")))
  } else if (itemType === "maths-complex-full") {
    execAsync(["bash", "-c", `curl -s "${wolframURLFull}?format=plaintext&output=JSON&appid=${appID}&input=${encodeURIComponent(entryText)}"`]).then((output) => {
      answer.set(JSON.parse(output));
    })
  } else if (itemType === "maths-complex") {
    execAsync(["bash", "-c", `curl -s "${wolframURL}?appid=${appID}&input=${encodeURIComponent(entryText)}"`]).then((output) => {
      answer.set(output);
    });
  } else {
    answer.set("N/A");
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
const items: Variable<string[]> = Variable([]);
const itemsWatcher: Variable<void> = Variable.derive([itemType, search, pre], (itemType, search, pre) => {
  if (itemType !== "files-home" && itemType !== "files-root") {
    items.set([]);
    return;
  }
  execAsync(["bash", "-c", `ls ${itemType === "files-home" ? "/home/adam/" : "/"}${pre} -a | grep "${search.replace(/\./g, "\\.")}"`]).then((output) => {
    items.set(output.split("\n").filter(function (value, index, arr) { return value !== "." && value !== ".."; }));
  }).catch(print);
});

const suggestions = Variable([])
const suggestionsWatcher = Variable.derive([query, itemType], (query, itemType) => {
  if (itemType !== "web") {
    suggestions.set([])
    return
  }
  execAsync(["bash", "-c", `curl -s "${suggestURL}?q=${encodeURIComponent(query.slice(1))}"`]).then((output) => {
    suggestions.set(query.slice(1) ? JSON.parse(output) : []);
  })
})

export default function AppLauncher() {
  let appData: Apps.Application[] = [];

  const Items = Variable.derive([itemType, query, answer, suggestions, items], (itemType, query, answer: any, suggestions, items) => {

    switch (itemType) {
      case "app":
        appData = apps.fuzzy_query(query);
        return appData.map((app: Apps.Application) => (
          <button
            className={"app-button"}
            on_Clicked={() => {
              app.launch();
              App.toggle_window(WINDOW_NAME);
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
      case "maths": case "maths-complex":
        return (answer !== "") ? (
          <button
            className={"Non-app"}
            on_Clicked={() => {
              execAsync(`wl-copy ${answer}`);
              App.toggle_window(WINDOW_NAME);
            }}
          >
            <label wrap label={`${answer}`} />
          </button>
        ) : (<box />);
      case "maths-complex-full":
        return (typeof answer !== "string" && answer) ? answer.queryresult.pods.map((pod: any) => (
          <button
            className={"Non-app"}
            on_Clicked={() => {
              execAsync(`wl-copy ${pod.subpods[0].plaintext}`);
              App.toggle_window(WINDOW_NAME);
            }}
          >
            <box className="AppText" vertical valign={Gtk.Align.CENTER}>
                <label className="AppName" label={pod.title} xalign={0} wrap />
                {pod.subpods && pod.subpods.map((subpod: any) => (
                  <label
                    className="AppDescription"
                    label={subpod.plaintext}
                    xalign={0}
                    wrap
                  />
                ))}
              </box>
          </button>
        )) : (<box />);
      case "files-home": case "files-root":
        return items.map((item) => (
          <button
            className={"Non-app"}
            on_Clicked={() => {
              execAsync(["bash", "-c", `xdg-open ${itemType === "files-home" ? "/home/adam/" : "/"}${pre.get()}${item}`]);
              App.toggle_window(WINDOW_NAME);
            }}
          >
            <label label={item} wrap />
          </button>
        ));
      case "web":
        // adding the original query to the suggestions
        return suggestions.length ? [...new Set([query.slice(1), ...suggestions[1]])].map((suggestion: string) => (
          <button
            className={"Non-app"}
            on_Clicked={() => {
              execAsync(`xdg-open ${searchURL}?q=${encodeURIComponent(suggestion)}`);
              App.toggle_window(WINDOW_NAME);
            }}
          >
            <label label={`${suggestion}`} wrap />
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
    onActivate: () => {
      switch (itemType.get()) {
        case "app":
          appData[0]?.launch();
          break;
        case "maths": case "maths-complex":
          execAsync(`wl-copy ${answer.get()}`);
          break;
        case "maths-complex-full":
          execAsync(`wl-copy ${answer.get().queryresult.pods[0].subpods[0].plaintext}`);
          break;
        case "web":
          execAsync(`xdg-open ${searchURL}?q=${encodeURIComponent(query.get().slice(1))}`);
          break;
        case "files-home":
          execAsync(["bash", "-c", `xdg-open /home/adam/${pre.get()}${items.get()[0]}`]);
          break;
        case "files-root":
          execAsync(["bash", "-c", `xdg-open /${pre.get()}${items.get()[0]}`]);
          break;
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
      visible={false}
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
          } else {
            Entry.grab_focus();
          }
        });
      }}
    >
      <box className="AppLauncher" vertical>
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