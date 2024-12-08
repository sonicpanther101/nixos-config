import { exec, execAsync, bind, Variable, writeFile, timeout } from "astal";
import { App, Astal, Gdk, Gtk, Widget } from "astal/gtk3";
import GtkSource from "gi://GtkSource?version=3.0";
import Pango from "gi://Pango?version=1.0";
import Gio from "gi://Gio?version=2.0";
import { testURL, testO } from "../../../../../../.night/test";
import md2pango, { markdownTest } from "./components/apis/md2pango";

const WINDOW_NAME = "apis";
const CUSTOM_SOURCEVIEW_SCHEME_PATH = "/home/adam/nixos-config/modules/home/ags/new ags/widget/components/apis/codeblocktheme.xml";
const LATEX_DIR = "/home/adam/.cache/ags/latex";

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

function loadCustomColorScheme(filePath: string) {
  // Read the XML file content
  const file = Gio.File.new_for_path(filePath);
  const [success, contents] = file.load_contents(null);

  if (!success) {
    logError('Failed to load the XML file.');
    return;
  }

  // Parse the XML content and set the Style Scheme
  const schemeManager = GtkSource.StyleSchemeManager.get_default();
  const parent = file.get_parent();
  if (parent) {
    const path = parent.get_path() ?? '';
    schemeManager.append_search_path(path);
  }
}
loadCustomColorScheme(CUSTOM_SOURCEVIEW_SCHEME_PATH);

execAsync(['bash', '-c', `rm -rf ${LATEX_DIR}/*`]).catch(print);

const TextBlock = (content = '') => (
  <label
    wrapMode={Pango.WrapMode.WORD_CHAR}
    className=""
    useMarkup
    xalign={0}
    wrap
    selectable
    label={content}
  />
)

const Divider = () => (
  <box className="sidebar-chat-divider"/>
)

function substituteLang(str: string) {
  const subs = [
    { from: 'javascript', to: 'js' },
    { from: 'bash', to: 'sh' },
  ];
  for (const { from, to } of subs) {
    if (from === str) return to;
  }
  return str;
}

class LatexViewArea {
  output: Gtk.Widget;
  constructor() {
    this.output = new Astal.Box();
  }
  
  async render(text: string): Promise<void> {

    const timeSinceEpoch = Date.now();
    const fileName = `${timeSinceEpoch}.png`;

    print(`wget "https://math.vercel.app?from=${text}" -O ${LATEX_DIR}/${fileName}`)
    exec(['bash', '-c', `wget "https://math.vercel.app?from=${text}" -O ${LATEX_DIR}/${fileName}`]);


    this.output = (
      <box>
        <icon className={"latex-icon"} css={"font-size: 30rem;"} icon={`${LATEX_DIR}/${fileName}`}/>
      </box>
    )
  }
}

class WholeThing {
  output: Gtk.Widget;
  latexViewArea: LatexViewArea

  constructor(latexViewArea: LatexViewArea, text = '') {
    this.latexViewArea = latexViewArea
    this.latexViewArea.render(text);
    this.output = (
      <box homogeneous>
        <scrollable
          hscroll={Gtk.PolicyType.AUTOMATIC}
          vscroll={Gtk.PolicyType.NEVER}
        >
          {this.latexViewArea.output}
        </scrollable>
      </box>
    );
  }

  udateText(text: string): void {
    this.latexViewArea.render(text);
    this.output = (
      <box homogeneous className="latex">
        <scrollable
          hscroll={Gtk.PolicyType.ALWAYS}
          vscroll={Gtk.PolicyType.NEVER}
        >
          {this.latexViewArea.output}
        </scrollable>
      </box>
    );
  }
}

const Latex = (content = '') => {
  const wholeThing = new WholeThing(new LatexViewArea(), content);

  return wholeThing.output;
}

const HighlightedCode = (content: string, lang: string) => {
  const buffer = new GtkSource.Buffer();
  const sourceView = new GtkSource.View({
    buffer: buffer,
    wrap_mode: Gtk.WrapMode.NONE,
    visible: true
  });
  const langManager = GtkSource.LanguageManager.get_default();
  let displayLang = langManager.get_language(substituteLang(lang)); // Set your preferred language
  if (displayLang) {
    buffer.set_language(displayLang);
  }
  const schemeManager = GtkSource.StyleSchemeManager.get_default();
  buffer.set_style_scheme(schemeManager.get_scheme("custom"));
  buffer.set_text(content, -1);
  return sourceView;
}

const topBar = (content: string, lang: string) => (
  <box>
    <label label={lang} />
    <box hexpand />
    <button
      className="codeblock-copy"
      onClicked={() => {
        execAsync([`wl-copy`, `${content}`]);
      }}
    >
      <box>
        <icon icon="edit-copy" />
        <label label="Copy" />
      </box>
    </button>
  </box>
)

const codeBlock = (content: string, lang: string) => (
  <box
    vertical
    className="codeblock"
  >
    {topBar(content, lang)}
    <box homogeneous>
      <scrollable
        hscroll={Gtk.PolicyType.AUTOMATIC}
        
        vscroll={Gtk.PolicyType.NEVER}
      >
        {HighlightedCode(content, lang)}
      </scrollable>
    </box>
  </box>
)

class CodeBlock {
  output: Gtk.Widget;
  lang: string;

  constructor(content = '', lang = 'txt') {

    this.lang = lang

    if (lang == 'tex' || lang == 'latex') {
      this.output = Latex(content);
      return this;
    }

    this.output = codeBlock(content, lang); 
  }

  updateText(text: string): void {
    
    if (this.lang == 'tex' || this.lang == 'latex') {
      this.output = Latex(text);
      return;
    }

    this.output = codeBlock(text, this.lang);
  }
}

const MessageFormatting = (message: string) => {
  const output: Variable<(Gtk.Widget | CodeBlock)[]> = Variable([TextBlock()]);

  let lines: string[] = message.split('\n');
  let lastProcessed: number = 0;
  let inCode: boolean = false;
  for (const [index, line] of lines.entries()) {
    // Code blocks
    const codeBlockRegex = /^\s*```([a-zA-Z0-9]+)?\n?/;
    if (codeBlockRegex.test(line)) {
      const kids = output.get();
      const lastLabel: any = kids[kids.length - 1];
      const blockContent: string = lines.slice(lastProcessed, index).join('\n');
      if (!inCode) { 
        lastLabel.label = md2pango(blockContent);
        output.set([...kids.slice(0, kids.length - 1), lastLabel]);
        output.set([...kids, new CodeBlock('', codeBlockRegex.exec(line)?.[1] ?? '')]);
      } else {
        lastLabel.updateText(blockContent);
        output.set([...kids.slice(0, kids.length - 1), lastLabel]);
        output.set([...kids, TextBlock()]);
      }

      lastProcessed = index + 1;
      inCode = !inCode;
    }

    const dividerRegex = /^\s*---/;
    if (!inCode && dividerRegex.test(line)) {
      const kids: (Gtk.Widget | CodeBlock)[] = output.get();
      const lastLabel: Widget.Label = kids[kids.length - 1] as Widget.Label;
      const blockContent = lines.slice(lastProcessed, index).join('\n');
      lastLabel.label = md2pango(blockContent);
      output.set([...kids.slice(0, kids.length - 1), lastLabel]);
      output.set([...kids, Divider(), TextBlock()]);
      lastProcessed = index + 1;
    }
  }

  if (lastProcessed < lines.length) {
    const kids: (Gtk.Widget | CodeBlock)[] = output.get();
    const lastLabel: any = kids[kids.length - 1];
    let blockContent = lines.slice(lastProcessed, lines.length).join('\n');
    if (!inCode) {
      lastLabel.label = md2pango(blockContent);
      output.set([...kids.slice(0, kids.length - 1), lastLabel]);
    } else {
      lastLabel.updateText(blockContent);
      output.set([...kids.slice(0, kids.length - 1), lastLabel]);
    }
  }

  return output.get().map((widget) => (widget instanceof CodeBlock) ? widget.output : widget);
}

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
      return GeminiChat.get().slice(1).map((message: string, i) => (
        <box vertical className={`message ${(i % 2 === 0 ? "bot" : "user")}`}>
          <box className={"testing"} vertical>
            {MessageFormatting(message)}
          </box>
          <icon icon={"nemo-horizontal-layout-symbolic"} css={"font-size: 15rem; margin-top: -5rem; margin-bottom: -5rem;"}/>
          <label label={message} wrap wrapMode={Pango.WrapMode.WORD_CHAR} selectable/>
        </box>
      ));
    } else if (APItype === "ChatGPT") {
      return (<box/>);
    } else if (APItype === "test") {
      return testChat.get().map((message, i) => ((i % 2 === 1) ? (
        <label label={message} className={`message user`} wrap selectable/>
      ) : (
        <box vertical>
          <button
            className={"message image"}
            onClick={(_, e: Astal.ClickEvent) => onClick(e, message)}
          >
            <icon icon={message[0]} visible={message[0] !== "Nothing"} />
          </button>
          <label label={
            message[1].match(
              /.{1,20}/g
            ).join("\n")
          } wrap wrapMode={Pango.WrapMode.WORD_CHAR} selectable/>
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