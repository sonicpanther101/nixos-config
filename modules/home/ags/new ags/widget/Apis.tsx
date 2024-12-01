import { exec, execAsync, bind, Variable } from "astal";
import { App, Astal, Gdk, Gtk, Widget } from "astal/gtk3";
import { testURL, testO } from "../../../../../../.night/test";

const WINDOW_NAME = "apis";

const input = Variable<string>("");
const APItype = Variable<"Gemini" | "ChatGPT" | "test">("Gemini");
const changed = Variable(false);

const typeIcon = {
  Gemini: "google",
  ChatGPT: "accessories-screenshot",
  test: "advert-block"
}

const systemPrompt = Variable<string>("systemPrompt");
const GeminiChat = Variable<string[]>([systemPrompt.get(),"Hi, How can I help?"]);
const API_KEY = "AIzaSyB-8_m7kiuNGgfNs_lns0ILwrrERfqfhjM"
const geminiURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent";

const testChat = Variable<any[]>([]);

export default function APIs() {

  const Entry = new Widget.Entry({
    text: bind(input),
    hexpand: true,
    canFocus: true,
    placeholderText: "Search",
    className: "Input",
    onActivate: () => {
      switch (APItype.get()) {
        case "Gemini":
          GeminiChat.set([...GeminiChat.get(), input.get()]);
          input.set("");
          print(`curl -s ${geminiURL}?key=${API_KEY}\
            -H "Content-Type: application/json" \
            -X POST \
            -d '${JSON.stringify({
              contents: [{
                parts: GeminiChat.get().map((message) => ({text: message}))
              }]
            })}'
          `)
          GeminiChat.set([...GeminiChat.get(), JSON.parse(exec(["bash", "-c", `curl -s ${geminiURL}\\?key=${API_KEY}\
            -H "Content-Type: application/json" \
            -X POST \
            -d '${JSON.stringify({
              contents: [{
                parts: GeminiChat.get().map((message) => ({text: message}))
              }]
            })}'
          `])).candidates[0].content.parts[0].text]);
          break;
        case "ChatGPT":
          break;
        case "test":
          testChat.set([input.get(), ...testChat.get()]);
          input.set("");
          let output = exec(["bash", "-c", `curl -s "${testURL}${encodeURIComponent(testChat.get()[0])}"`])
          if (output === "") {
            testChat.set(["Nothing", ...testChat.get()]);
          } else {
            let randomIndex = Math.floor(Math.random() * JSON.parse(output).length);
            let imgURL = JSON.parse(output)[randomIndex].sample_url       
            exec(["bash", "-c", `curl ${imgURL} -o /home/adam/.night/api/${JSON.parse(output)[randomIndex].tags.replace(/ /g, "-").replace(/\(/g, "-").replace(/\)/g, "-").replace(/&#039;/g, "-").split("").slice(0, 250).join("")}.${imgURL.split(".")[imgURL.split(".").length - 1]}`])
            testChat.set([[`/home/adam/.night/api/${JSON.parse(output)[randomIndex].tags.replace(/ /g, "-").replace(/\(/g, "-").replace(/\)/g, "-").replace(/&#039;/g, "-").split("").slice(0, 250).join("")}.${imgURL.split(".")[imgURL.split(".").length - 1]}`, JSON.parse(output)[randomIndex].tags, JSON.parse(output)[randomIndex].id], ...testChat.get()]);
          }
          break;
      }
      input.set("");
      changed.set(!changed.get());
    },
    setup: (self) => {
      self.hook(self, "notify::text", () => {
        input.set(self.get_text());
      });
    },
  });

  const onClick = (e: Astal.ClickEvent, message: any) => {
    if (e.button === Gdk.BUTTON_PRIMARY) {
      if (message[0] === "Nothing") {
        return;
      }
      exec(["bash", "-c", `xdg-open ${message[0]}`]);
      App.toggle_window(WINDOW_NAME);
    } else if (e.button === Gdk.BUTTON_SECONDARY) {
      if (message[0] === "Nothing") {
        return;
      }
      exec(["bash", "-c", `xdg-open ${testO}${message[2]}`]);
      App.toggle_window(WINDOW_NAME);
    }
  };

  const Items = Variable.derive([changed, APItype], (changed, APItype) => { 
    if (APItype === "Gemini") { 
      return GeminiChat.get().slice(1).map((message, i) => (
        <label label={message} className={`message ${(i % 2 === 0 ? "bot" : "user")}`} wrap/>
      ));
    } else if (APItype === "ChatGPT") {
      return (<box/>);
    } else if (APItype === "test") {
      return testChat.get().map((message, i) => ((i % 2 === 1) ? (
        <label label={message} className={`message user`} wrap/>
      ) : (
        <box vertical>
          <button
            className={"message image"}
            onClick={(_, e: Astal.ClickEvent) => onClick(e, message)}
          >
            <icon icon={message[0]} visible={message[0] !== "Nothing"} />
          </button>
          <entry text={
            message[1].match(
              /.{1,20}/g
            ).join("\n")
          } widthChars={20}/>
        </box>
      )));
    }
    return (<box/>);
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
        <centerbox>
          <box />
          <box className="APItype">
            {
              (["Gemini", "ChatGPT", "test"] as const).map((type: "Gemini" | "ChatGPT" | "test") => (
                <button
                  onClick={() => {
                    APItype.set(type);
                    Entry.grab_focus();
                  }}
                >
                  <icon icon={typeIcon[type]} />
                </button>
              ))
            }
          </box>
          <box />
        </centerbox>
        <scrollable vexpand hscroll={Gtk.PolicyType.NEVER}>
          <box className="ItemName" vertical spacing={5}>
            {bind(Items)}
          </box>
        </scrollable>
        {Entry}
      </box>
    </window>
  );
}