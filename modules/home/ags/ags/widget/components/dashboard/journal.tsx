import { readFileAsync, Variable, execAsync, bind } from "astal"

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
  entries?: Entry[];
}

interface Entry {
  title: string;
  content?: string;
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

const refresh = <button
  className="journal-refresh"
  onClicked={() => {
    readUpdate()
  }}
>
  <label label="↻" className="journal-button-label" />
</button>;

function readUpdate() {
  execAsync(['bash', '-c', `curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${token}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/gists/${gistID}`]).then(out => {
    
    const data = JSON.parse(out)["files"]["journal.json"]["content"]

    const entries = JSON.parse(data)    
    
    journal_list.set(entries)
  }).catch(print)
}

const Journal = (
  <box>

  </box>
)

export default Journal