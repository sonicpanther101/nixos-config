import { readFileAsync, Variable, execAsync, bind } from "astal"
import { Gtk } from "astal/gtk3";

const task_list = Variable([] as string[])
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
    task_list.set([self.get_text(), ...task_list.get()])
    input.set("")
    writeUpdate()
  }}
  setup={(self) => {
    self.hook(self, "notify::text", () => {
      input.set(self.get_text());
    });
  }}
/>;

const tasks_display = () => {

  task_list.set(task_list.get().filter(task => task !== ""));

  if (task_list.length === 0) {
    return [];
  }

  return []
}  
  

function readUpdate() {
  execAsync(['bash', '-c', `curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${token}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/gists/${gistID}`]).then(out => {
    
    const data = JSON.parse(out)["files"]["todo.txt"]["content"]
    
    task_list.set(data.split("\n"))
  }).catch(print)
}

function writeUpdate() {
  execAsync(['bash', '-c', `curl -L \
    -X PATCH \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${token}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/gists/${gistID} \
    -d '{"description":"Updated Gist","files":{"todo.txt":{"content":"${task_list.get().join("\\n")}"}}}'`]).catch(print);
}

export default function Tasks() {
  return (
    <box
      vertical
      vexpand
      className="tasks"
    >
      <scrollable
        vexpand
        hexpand
      >
        <box
          vertical
          hexpand
        >
          {bind(task_list).as((tasks) => tasks.map((task, i) => (
            <centerbox
              className={i % 2 === 0 ? "even-scroll" : "odd-scroll"}
              hexpand
            >
              <box hexpand>
                <box
                  vertical
                  hexpand
                >
                  <button
                    className={`task-up ${i % 2 === 0 ? "even-scroll" : "odd-scroll"} ${i === 0 ? "task-up-disabled" : ""}`}
                    label="up"
                    onClick={() => {
                      let temp = task
                      let templist = task_list.get()
                      templist.splice(i, 1)
                      templist.splice(i - 1, 0, temp)
                      task_list.set(templist)
                      writeUpdate()
                    }}
                  />
                  <button
                    className={`task-down ${i % 2 === 0 ? "even-scroll" : "odd-scroll"} ${i === task_list.length - 1 ? "task-down-disabled" : ""}`}
                    label="down"
                    onClick={() => {
                      let temp = task
                      let templist = task_list.get()
                      templist.splice(i, 1)
                      templist.splice(i + 1, 0, temp)
                      task_list.set(templist)
                      writeUpdate()
                    }}
                  />
                </box>
                <button
                  label="✎"
                  onClick={() => {
                    input.set(task)
                    entry.grab_focus()
                    task_list.set(task_list.get().splice(i, 1))
                    writeUpdate()
                  }}
                />
                <label hexpand label={task} />
              </box>
              <box />
              <box >
                <button
                  label="✕"
                  onClick={() => {
                    task_list.set(task_list.get().splice(i, 1))
                    writeUpdate()
                  }}
                />
              </box>
            </centerbox>
          )))}
        </box>
      </scrollable>
      <box>
        {refresh}
        {entry}
      </box>
    </box>
  )
}