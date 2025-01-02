import { readFileAsync, Variable, execAsync, bind } from "astal"
import { Gtk, Widget } from "astal/gtk3";
import Pango from "gi://Pango?version=1.0";

const task_list = Variable<TaskDefinition[]>([])
const changed = Variable<boolean>(false)
let gistID = ""
let token = ""

function changedHandler() {
  changed.set(!changed.get())
}

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

function getTarget(treePosition: number[], handler: (target: TaskDefinition) => void) {
  let temp = task_list.get();
  const target = treePosition.slice(1).reduce((acc, curr, index) => {
    if (index >= treePosition.length - 1) {
      return acc;
    } else {
      return acc.subtasks?.[curr] || acc; 
    }
  }, temp[treePosition[0]]); 

  handler(target);
  task_list.set(temp); 
  changedHandler();
}

function getTargetParent(treePosition: number[], handler: (parent: TaskDefinition) => void) {
  let temp = task_list.get();
  const parent = treePosition.slice(1).reduce((acc, curr, index) => {
    if (index >= treePosition.length - 2) {
      return acc;
    } else {
      return acc.subtasks?.[curr] || acc; 
    }
  }, temp[treePosition[0]]); 

  handler(parent);
  task_list.set(temp); 
  changedHandler();
}

function createTasks(definition: TaskDefinition, i: number, treePosition: number[]) {
  
  return (
  <box
    hexpand
    className={i % 2 === 0 ? "even-scroll" : "odd-scroll"}
  >
    <box
      vertical
      vexpand={false}
    >
      <button
        vexpand
        className={`task-up ${i === 0 ? "task-up-disabled" : ""}`}
        onClick={() => {
          let temp = definition
          if (treePosition.length === 1) {
            let templist = task_list.get()
            templist.splice(i, 1)
            templist.splice(i - 1, 0, temp)
            task_list.set(templist)
            changedHandler()
          } else {
            getTargetParent(treePosition, (parent) => {
              parent.subtasks?.splice(i, 1)
              parent.subtasks?.splice(i - 1, 0, temp)
            })
          }
          writeUpdate()
        }}
      >
        <label label="⏶" className="task-button-label" />
      </button>
      <button
        vexpand
        className={`task-down ${i === task_list.length - 1 ? "task-down-disabled" : ""}`}
        onClick={() => {
          let temp = definition
          if (treePosition.length === 1) {
            let templist = task_list.get()
            templist.splice(i, 1)
            templist.splice(i + 1, 0, temp)
            task_list.set(templist)
            changedHandler()
          } else {
            getTargetParent(treePosition, (parent) => {
              parent.subtasks?.splice(i, 1)
              parent.subtasks?.splice(i + 1, 0, temp)
            })
          }
          writeUpdate()
        }}
      >
        <label label="⏷" className="task-button-label" />
      </button>
    </box>
    <button
      className="task-edit"
      onClick={() => {
        getTarget(treePosition, (target) => {
          target.editMode = !target.editMode
        })
      }}
    >
      <label label="✎" className="task-button-label" />
    </button>
    {definition.subtasks && <button
      className="toggle-subtasks"
      onClick={() => {
        getTarget(treePosition, (target) => {
          target.subtasksShown = !target.subtasksShown
        })
      }}
    >
      <label label={definition.subtasksShown ? "▼" : "▶"} css="font-size: 1rem;"className="task-button-label" />
    </button>}
    <box vertical>
      {definition.editMode ?
        <entry text={definition.label} className="task" onActivate={(self) => getTarget(treePosition, (target) => { target.editMode = false; target.label = self.get_text() })} hexpand halign={Gtk.Align.START} /> :
        <label hexpand label={definition.label} wrap wrapMode={Pango.WrapMode.WORD_CHAR} halign={Gtk.Align.START} className="task" />}
      {definition.subtasksShown && definition.subtasks && definition.subtasks.map((task, i) => createTasks(task, i, [...treePosition, i]))}
    </box>
    <button
      className="subtask-add"
      onClick={() => {
        getTarget(treePosition, (target) => {
          target.subtasks = target.subtasks || []
          target.subtasks.splice(0, 0, { label: "", editMode: true })
          target.subtasksShown = true
        })
      }}
    >
      <label label="+" className="task-button-label" />
    </button>
    <button
      className="task-delete"
      onClick={() => {
        if (treePosition.length === 1) {
          let temp = task_list.get()
          temp.splice(i, 1)
          task_list.set(temp)
          changedHandler()
        } else {
          getTargetParent(treePosition, (parent) => {
            parent.subtasks?.splice(i, 1)
          })
        }
        writeUpdate()
      }}
      >
        <label label="✕" className="task-button-label" />
      </button>
  </box>
  )
};

const items = Variable.derive([task_list, changed], (task_list, changed) => {
  return task_list.map((task, i) => createTasks(task, i, [i]))
})
 
function readUpdate() {
  execAsync(['bash', '-c', `curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${token}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/gists/${gistID}`]).then(out => {
    
    const data = JSON.parse(out)["files"]["todo.txt"]["content"]

    const tasks = JSON.parse(data)

    const complexTasks: TaskDefinition[] = [
  {
    label: "Project A",
    subtasks: [
      {
        label: "Phase 1",
        subtasks: [
          {
            label: "Task 1.1",
            subtasks: [
              {
                label: "Subtask 1.1.1",
              },
              {
                label: "Subtask 1.1.2",
                subtasks: [
                  {
                    label: "Subtask 1.1.2.1",
                  },
                  {
                    label: "Subtask 1.1.2.2",
                  },
                ],
              },
            ],
          },
          {
            label: "Task 1.2",
          },
        ],
      },
      {
        label: "Phase 2",
      },
    ],
  },
  {
    label: "Project B",
    subtasks: [
      {
        label: "Task 2.1",
        subtasks: [
          {
            label: "Subtask 2.1.1",
          },
        ],
      },
    ],
  },
    ];
    
    
    
    task_list.set(complexTasks)
  }).catch(print)
}

function writeUpdate() {
  print("update")

  function removeDisplayProperties(task: TaskDefinition): TaskDefinition {
    return {
      label: task.label,
      subtasks:
        task.subtasks?.map(subtask =>
          removeDisplayProperties(subtask)
        ),
    };
  }

  const out = JSON.stringify(task_list.get().map(removeDisplayProperties)).replace(/{/g, '\n{')

  print(out)

  print(`curl -L \
    -X PATCH \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${token}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/gists/${gistID} \
    -d '{"description":"Updated Gist","files":{"todo.txt":{"content":"${out}"}}}'
  `)

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
        {bind(items)}
      </box>
    </scrollable>
    <box>
      {refresh}
      {Entry}
    </box>
  </box>
)

export default Tasks