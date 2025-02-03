import { readFileAsync, Variable, execAsync, bind } from "astal"
import { Gtk, Widget } from "astal/gtk3";
import Pango from "gi://Pango?version=1.0";

const journal_list = Variable<JournalDefinition[]>([])
const changed = Variable<boolean>(false)
const input = Variable("")
let gistID = ""
let token = ""

function changedHandler() {
  changed.set(!changed.get())
}

interface JournalDefinition {
  date: string;
  entries: Entry[];
}

interface Entry {
  label: string;
  editMode?: boolean
}

readFileAsync(`/home/adam/.cache/astal/secrets.json`).then((secrets) => {
  let parsed = JSON.parse(secrets)
  gistID = parsed.journal_gist_id
  token = parsed.token
  if (gistID === "") {
    print("journal id not found in secrets.json")
    return
  } else if (token === "") {
    print("token not found in secrets.json")
    return
  }
  readUpdate()
}).catch(print)

function changeJournal(j: number,i: number, hander: (entry: Entry) => void) {
  let temp = journal_list.get()
  hander(temp[j].entries[i])
  journal_list.set(temp)
  changedHandler()
}

const entryFormat = (entry: Entry, i: number, j: number) => (
  <box
    hexpand
    className={i % 2 === 0 ? "even-scroll" : "odd-scroll"}
  >
    <button
      className="journal-edit"
      onClick={() => {
        changeJournal(j,i, (entry) => {
          entry.editMode = !entry.editMode
        })
      }}
    >
      <label label="✎" className="journal-button-label" />
    </button>
    {entry.editMode ?
      <entry
        text={entry.label}
        widthChars={120}
        className="journal edit"
        onActivate={(self) => {
          changeJournal(j,i, (entry) => {
            entry.editMode = false
            entry.label = self.get_text()
          })
          writeUpdate();
        }}
        hexpand
        onRealize={(self) => { self.grab_focus() }}
        halign={Gtk.Align.START}
      /> :
      <label hexpand label={entry.label} wrap wrapMode={Pango.WrapMode.WORD_CHAR} halign={Gtk.Align.START} className="journal" />
    }
    <button
      className="journal-delete"
      onClick={() => {
        let temp = journal_list.get()
        temp[j].entries.splice(i, 1)
        if (temp[j].entries.length === 0) {
          temp.splice(j, 1)
        }
        journal_list.set(temp)
        writeUpdate()
      }}
    >
      <label label="✕" className="journal-button-label" />
    </button>
  </box>
)

function createEntries(definition: JournalDefinition, j: number) {
  print(j, "srysfghdfgh")
  return (
    <box vertical>
      <label label={definition.date} className={`journal-date ${j === 0 ? "top" : ""}`} halign={Gtk.Align.START} />
      {definition.entries.map((entry, i) => entryFormat(entry, i, j))}
    </box>
  )
}

const refresh = <button
  className="journal-refresh"
  onClicked={() => {
    readUpdate()
  }}
>
  <label label="↻" className="journal-button-label" />
</button>;

const Entry = new Widget.Entry({
  text: bind(input),
  hexpand: true,
  canFocus: true,
  placeholderText: "Enter journal entry",
  className: "journal-entries",
  onActivate: (self: Widget.Entry) => {
    if (self.get_text() === "") {
      return
    }
    let date = new Date(Date.now()).toDateString()
    if (journal_list.get().filter((item) => item.date === date).length > 0) {
      let temp_list = journal_list.get()
      let temp = [...temp_list.filter((item) => item.date === date)[0].entries, { label: self.get_text() }]
      let index = temp_list.findIndex((item) => item.date === date)
      temp_list.splice(index, 1, {date: date, entries: temp})
      journal_list.set(temp_list)
    } else {
      journal_list.set([{date: date, entries: [{label: self.get_text()}]}, ...journal_list.get()])
    }
    
    input.set("")
    writeUpdate()
  },
  setup: (self) => {
    self.hook(self, "notify::text", () => {
      input.set(self.get_text());
    });
  }
});

function readUpdate() {
  execAsync(['bash', '-c', `curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${token}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/gists/${gistID}`]).then(out => {
    
    const data = JSON.parse(out)["files"]["journal.json"]["content"]

    const entries = JSON.parse(data)

    journal_list.set(entries)
    changedHandler();
  }).catch(print)
}

function writeUpdate() {
  print("update")

  const out = JSON.stringify(journal_list.get()).replace(/{/g, '\\n{').replace(/]/g, '\\n]').replace(/"/g, "\\\"")

  changedHandler();

  execAsync(['bash', '-c', `curl -L \
    -X PATCH \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${token}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/gists/${gistID} \
    -d '{"description":"Updated Gist","files":{"journal.json":{"content":"${out}"}}}'
  `]).catch(print);
}

const items = Variable.derive([journal_list, changed], (journal_list, changed) => {
  return journal_list.map((day, i) => createEntries(day, i))
})

const Journal = (
  <box
    className="journal"
    vertical
  >
    <scrollable
      vexpand
      hexpand
    >
      <box
        vertical
      >
        {bind(items)}
      </box>
    </scrollable>
    <box>
      {refresh}
      {Entry}
    </box>
  </box>
)

export default Journal