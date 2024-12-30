import { readFileAsync, Variable, execAsync, bind } from "astal"
import { Gtk, Widget } from "astal/gtk3";
import Pango from "gi://Pango?version=1.0";

const task_list = Variable<TaskDefinition[]>([])
let gistID = ""
let token = ""

readFileAsync(`/home/adam/.cache/astal/secrets.json`).then((secrets) => {
  let parsed = JSON.parse(secrets)
  gistID = parsed.todo_gist_id
  token = parsed.token
  if (gistID === "") {
    print("todo directory not found in secrets.json")
    return
  } else if (token === "") {
    print("token not found in secrets.json")
    return
  }
  readUpdate()
}).catch(print)

const refresh = new Widget.Button({
  className: "task-refresh",
  label: "↻",
  onClicked: () => {
    readUpdate()
  }
});

const input = Variable("")

const Entry = new Widget.Entry({
  text: bind(input),
  hexpand: true,
  canFocus: true,
  placeholderText: "Enter task",
  className: "tasks-entry",
  onActivate: (self: Widget.Entry) => {
    if (self.get_text() === "") {
      return
    }
    task_list.set([{label: self.get_text()}, ...task_list.get()])
    input.set("")
    writeUpdate()
  },
  setup: (self) => {
    self.hook(self, "notify::text", () => {
      input.set(self.get_text());
    });
  }
});

interface TaskDefinition {
  label: string;
  subtasks?: TaskDefinition[];
  editMode?: boolean;
  subtasksShown?: boolean;
}

const createTasks = (definition: TaskDefinition, i: number, treePosition: number[]) => (
  <box
    hexpand
    className={i % 2 === 0 ? "even-scroll" : "odd-scroll"}
  >
    <box
      vertical
    >
      <button
        className={`task-up ${i === 0 ? "task-up-disabled" : ""}`}
        onClick={() => {
          let temp = definition
          let templist = task_list.get()
          templist.splice(i, 1)
          templist.splice(i - 1, 0, temp)
          task_list.set(templist)
          writeUpdate()
        }}
      >
        <label label="⏶" className="task-button-label" />
      </button>
      <button
        className={`task-down ${i === task_list.length - 1 ? "task-down-disabled" : ""}`}
        onClick={() => {
          let temp = definition
          let templist = task_list.get()
          templist.splice(i, 1)
          templist.splice(i + 1, 0, temp)
          task_list.set(templist)
          writeUpdate()
        }}
      >
        <label label="⏷" className="task-button-label" />
      </button>
    </box>
    <button
      className="task-edit"
      onClick={() => {
        input.set(definition.label)
        Entry.grab_focus()
        task_list.set(task_list.get().splice(i, 1))
        writeUpdate()
      }}
    >
      <label label="✎" className="task-button-label" />
    </button>
    {definition.subtasks && <button
      className="toggle-subtasks"
      onClick={() => {
        let temp = task_list.get();
        if (treePosition.length === 1) {
          temp[treePosition[0]].subtasksShown = !temp[treePosition[0]].subtasksShown;
          // print(temp[treePosition[0]].subtasksShown)
        }
        task_list.set(temp);
        // print(JSON.stringify(task_list.get()))
      }}
    >
      <label label={JSON.stringify(definition)} css="font-size: 1rem;" wrap wrapMode={Pango.WrapMode.WORD_CHAR} className="task-button-label" />
    </button>}
    <box vertical>
      <label hexpand label={definition.label} wrap wrapMode={Pango.WrapMode.WORD_CHAR} halign={Gtk.Align.START} className="task" />
      {definition.subtasksShown && definition.subtasks && definition.subtasks.map((task, i) => createTasks(task, i, [...treePosition, i]))}
    </box>
    <button
      className="task-delete"
      onClick={() => {
        let temp = task_list.get()
        temp.splice(i, 1)
        task_list.set(temp)
        writeUpdate()
      }}
    ><label label="✕" className="task-button-label" /></button>
  </box>
);
 
function readUpdate() {
  execAsync(['bash', '-c', `curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${token}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/gists/${gistID}`]).then(out => {
    
    const data = JSON.parse(out)["files"]["todo.txt"]["content"]

    const tasks = JSON.parse(data)
    
    task_list.set(tasks)
  }).catch(print)
}

function writeUpdate() {
  print("update")

  const out = JSON.stringify(task_list.get()).replace(/{/g, '\n{')

  print(out)

  print(`curl -L \
    -X PATCH \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${token}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/gists/${gistID} \
    -d '{"description":"Updated Gist","files":{"todo.txt":{"content":"${out}"}}}'`)

  // execAsync(['bash', '-c', `curl -L \
  //   -X PATCH \
  //   -H "Accept: application/vnd.github+json" \
  //   -H "Authorization: Bearer ${token}" \
  //   -H "X-GitHub-Api-Version: 2022-11-28" \
  //   https://api.github.com/gists/${gistID} \
  //   -d '{"description":"Updated Gist","files":{"todo.txt":{"content":"${task_list.get().join("\\n")}"}}}'`]).catch(print);
}

const Tasks = (
  <box
    className="tasks"
    vertical
  >
    <scrollable
      vexpand
      hexpand
    >
      <box
        vertical
      >
        {bind(task_list).as((tasks) => tasks.map((task, i) => {
          print(JSON.stringify(task))
          return createTasks(task, i, [i])
        }))}
      </box>
    </scrollable>
    <box>
      {refresh}
      {Entry}
    </box>
  </box>
)

export default Tasks