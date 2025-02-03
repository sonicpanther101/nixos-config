import { readFileAsync, Variable, execAsync, bind } from "astal"
import { Gtk, Gdk, Widget, Astal } from "astal/gtk3";
import Pango from "gi://Pango?version=1.0";

const task_list = Variable<TaskDefinition[]>([])
const changed = Variable<boolean>(false)
const input = Variable("")
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
    print("todo id not found in secrets.json")
    return
  } else if (token === "") {
    print("token not found in secrets.json")
    return
  }
  readUpdate()
}).catch(print)

const refresh = <button
  className="task-refresh"
  onClicked={() => {
    readUpdate()
  }}
>
  <label label="↻" className="task-button-label" />
</button>;

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
  status?: number;
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

function getTargetParent(treePosition: number[], handler: (parent: TaskDefinition) => any) {
  let temp = task_list.get();
  const parent = treePosition.slice(1).reduce((acc, curr, index) => {
    if (index >= treePosition.length - 2) {
      return acc;
    } else {
      return acc.subtasks?.[curr] || acc; 
    }
  }, temp[treePosition[0]]); 
  
  handler(parent)
  task_list.set(temp); 
  changedHandler();
}

function createTasks(definition: TaskDefinition, i: number, treePosition: number[]) {
  
  let parent = treePosition.slice(1).reduce((acc, curr, index) => {
    if (index >= treePosition.length - 2) {
      return acc;
    } else {
      return acc.subtasks?.[curr] || acc; 
    }
  }, task_list.get()[treePosition[0]]);

  const onScroll: (_: Widget.EventBox, e: Astal.ScrollEvent) => void = (_: Widget.EventBox, e: Astal.ScrollEvent) => {
    let direction: -1 | 1 | null = null;
    if (e.direction == Gdk.ScrollDirection.SMOOTH) {
        direction = Math.sign(e.delta_y) as 1 | -1;
    } else if (e.direction == Gdk.ScrollDirection.UP) {
        direction = 1;
    } else if (e.direction == Gdk.ScrollDirection.DOWN) {
        direction = -1;
    }
    if (direction === null) return
    getTarget(treePosition, (target) => {
      target.status = (typeof target.status === "number") ? Math.min(100, Math.max(0, (Math.round(target.status/5)*5 === target.status ? (target.status - direction*5) : (Math.round(target.status/5)*5)))) : undefined;
    })
    writeUpdate()
  };

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
          if (i === 0) return
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
        <label label="⏶" className={`task-button-label ${i === 0 ? "task-up-disabled" : ""}`} />
      </button>
      <button
        vexpand
        className={`task-down ${(treePosition.length === 1 ? i === task_list.get().length - 1 : i + 1 === parent.subtasks?.length) ? "task-down-disabled" : ""}`}
        onClick={() => {
          if (treePosition.length === 1 ? i === task_list.get().length - 1 : i + 1 === parent.subtasks?.length) return
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
      className={`task-edit ${definition.subtasks?.length ? "" : "edit-rounded"}`}
      onClick={() => {
        getTarget(treePosition, (target) => {
          target.editMode = !target.editMode
        })
      }}
    >
      <label label="✎" className="task-button-label" />
    </button>
    {definition.subtasks?.length && <button
      className={`toggle-subtasks ${definition.subtasksShown ? "" : "not-toggled"}`}
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
        <entry
          text={definition.label}
          widthChars={120}
          className="task edit"
          onActivate={(self) => getTarget(treePosition, (target) => { target.editMode = false; target.label = self.get_text(); writeUpdate() })}
          hexpand
          onRealize={(self) => { self.grab_focus() }}
          halign={Gtk.Align.START}
        /> :
        <label hexpand label={definition.label} wrap wrapMode={Pango.WrapMode.WORD_CHAR} halign={Gtk.Align.START} className="task" />}
      {definition.subtasksShown && definition.subtasks && definition.subtasks.map((task, i) => createTasks(task, i, [...treePosition, i]))}
    </box>
      {(typeof definition.status === "number") ?
        <eventbox onScroll={onScroll}>
          <box>
            <slider max={100} step={1} className="status-slider" onDragged={self => { getTarget(treePosition, (target) => { target.status = Math.round(self.get_value()); writeUpdate() }); }} value={definition.status} />
            <label className="status-label" label={` ${definition.status === 100 ? "" : definition.status < 10 ? "  " : " "}${definition.status}%`} />
          </box>
        </eventbox> :
        <button
          className="status-add"
          onClick={() => {
            getTarget(treePosition, (target) => {
              target.status = 0
            })
          }}
        >
          <label label="Add Status" css="font-size: 0.6rem;" className="task-button-label" />
        </button>
      }
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
    
    const data = JSON.parse(out)["files"]["todo.json"]["content"]

    const tasks = JSON.parse(data)    
    
    task_list.set(tasks)
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
      status: task.status
    };
  }

  const out = JSON.stringify(task_list.get().map(removeDisplayProperties)).replace(/{/g, '\\n{').replace(/]/g, '\\n]').replace(/"/g, "\\\"")

  execAsync(['bash', '-c', `curl -L \
    -X PATCH \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${token}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/gists/${gistID} \
    -d '{"description":"Updated Gist","files":{"todo.json":{"content":"${out}"}}}'
  `]).catch(print);
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