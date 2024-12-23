import { readFileAsync, Variable, execAsync, bind } from "astal"
import { Gtk, Astal } from "astal/gtk3";
import Pango from "gi://Pango?version=1.0";

const task_list = Variable([] as TaskDefinition[])
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

const refresh = <button
  className="task-refresh"
  label="↻"
  on_clicked={() => {
    readUpdate()
  }}
/>;

const input = Variable("")

const entry = <entry
  hexpand
  className="tasks-entry"
  onActivate={(self) => {
    if (self.get_text() === "") {
      return
    }
    task_list.set([{label: self.get_text()}, ...task_list.get()])
    input.set("")
    writeUpdate()
  }}
  setup={(self) => {
    self.hook(self, "notify::text", () => {
      input.set(self.get_text());
    });
  }}
/>;

interface TaskDefinition {
  label: string;
  subtask?: TaskDefinition[];
}

export function createTasks(definition: TaskDefinition[]) {
  const result = [];

  for (let i = 0; i < definition.length; i++) {
    const item = (
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
                let temp = definition[i]
                let templist = task_list.get()
                templist.splice(i, 1)
                templist.splice(i - 1, 0, temp)
                task_list.set(templist)
                writeUpdate()
              }}
            ><label label="⏶" className="task-button-label" /></button>
            <button
              className={`task-down ${i === task_list.length - 1 ? "task-down-disabled" : ""}`}
              onClick={() => {
                let temp = definition[i]
                let templist = task_list.get()
                templist.splice(i, 1)
                templist.splice(i + 1, 0, temp)
                task_list.set(templist)
                writeUpdate()
              }}
            ><label label="⏷" className="task-button-label" /></button>
          </box>
          <button
            className="task-edit"
            onClick={() => {
              input.set(definition[i].label)
              entry.grab_focus()
              task_list.set(task_list.get().splice(i, 1))
              writeUpdate()
            }}
          ><label label="✎" className="task-button-label" /></button>
          <label hexpand label={definition[i].label} wrap wrapMode={Pango.WrapMode.WORD_CHAR} halign={Gtk.Align.START} className="task"/>
        <button
          hexpand={false}
          className="task-delete"
          onClick={() => {
            task_list.set(task_list.get().splice(i, 1))
            writeUpdate()
          }}
        ><label label="✕" className="task-button-label" /></button>
      </box>
    );
    result.push(item);
  }

  return result;
}  

function readUpdate() {
  execAsync(['bash', '-c', `curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${token}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/gists/${gistID}`]).then(out => {
    
    const data = JSON.parse(out)["files"]["todo.txt"]["content"]

    const lines = data.split('\n');
    const tasks: TaskDefinition[] = [];
    const stack: TaskDefinition[] = [];

    for (const line of lines) {
      const indentationLevel = line.match(/^\t*/)[0].length;
      const label = line.trim();

      if (indentationLevel === 0) {
        // New top-level task
        const task: TaskDefinition = { label };
        tasks.push(task);
        stack.push(task);
      } else {
        // Subtask
        const parentTask = stack[indentationLevel - 1];
        if (!parentTask.subtask) {
          parentTask.subtask = [];
        }
        const subtask: TaskDefinition = { label };
        parentTask.subtask.push(subtask);
        stack.push(subtask);
      }
    }
    task_list.set(tasks)
  }).catch(print)
}

function writeUpdate() {
  print("update")

  function encodeTask(task: TaskDefinition, indentationLevel: number): string {
    const label = task.label;
    const subtasks = task.subtask || [];

    let text = `${'\t'.repeat(indentationLevel)}${label}\n`;

    for (const subtask of subtasks) {
      text += encodeTask(subtask, indentationLevel + 1);
    }

    return text;
  }

  let text = '';

  for (const task of task_list.get()) {
    text += encodeTask(task, 0);
  }

  print(text0)

  // execAsync(['bash', '-c', `curl -L \
  //   -X PATCH \
  //   -H "Accept: application/vnd.github+json" \
  //   -H "Authorization: Bearer ${token}" \
  //   -H "X-GitHub-Api-Version: 2022-11-28" \
  //   https://api.github.com/gists/${gistID} \
  //   -d '{"description":"Updated Gist","files":{"todo.txt":{"content":"${task_list.get().join("\\n")}"}}}'`]).catch(print);
}

export default function Tasks() {
  return (
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
          {bind(task_list).as((tasks) => createTasks(tasks))}
        </box>
      </scrollable>
      <box>
        {refresh}
        {entry}
      </box>
    </box>
  )
}