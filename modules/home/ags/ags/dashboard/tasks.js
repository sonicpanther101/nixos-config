let task_list = []
let gistID = ""
let token = ""

Utils.readFileAsync(`/home/adam/.cache/ags/secrets.txt`).then((secrets) => {
    const secretsList = secrets.split("\n")
    for (const secret of secretsList) {
        const [name, value] = secret.split(":")
        if (name === "todo_gist_id") {
            gistID = value
        } else if (name === "token") {
            token = value
        }
    }
    if (gistID === "") {
        print("todo directory not found in secrets.txt")
        return
    } else if (token === "") {
        print("token not found in secrets.txt")
        return
    }
    readUpdate()
}).catch(err => print(err))

const refresh = Widget.Button({
    class_name: "task-refresh",
    label: "↻",
    on_clicked: () => {
        readUpdate()
    }
})

function readUpdate() {
    Utils.execAsync(['bash', '-c', `curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${token}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/gists/${gistID}`]).then(out => {
        
        const data = JSON.parse(out)["files"]["todo.txt"]["content"]

        Utils.writeFile(data, `/home/adam/.cache/ags/todo.txt`).catch(err => print(err))
        
        task_list = data.split("\n")
        list.children = tasks_display()
    }).catch(err => print(err))
}

function writeUpdate() {
    list.children = tasks_display()
    Utils.writeFile(task_list.join("\n"), `/home/adam/.cache/ags/todo.txt`).catch(err => print(err))
    Utils.execAsync(['bash', '-c', `curl -L \
  -X PATCH \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${token}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/gists/${gistID} \
  -d '{"description":"Updated Gist","files":{"todo.txt":{"content":"${task_list.join("\\n")}"}}}'`]).catch(err => print(err));
}

const readPoller = Variable("", {
    poll: [60000, () => readUpdate()]
})

const tasks_display = () => {

    task_list = task_list.filter(task => task !== "");

    if (task_list.length === 0) {
        return [];
    }

    return task_list.map((task, i) => Widget.CenterBox({
        class_name: `${i % 2 === 0 ? "even-scroll" : "odd-scroll"}`,
        hpack: "fill",
        start_widget: Widget.Box({
            children: [
                Widget.Box({
                    vertical: true,
                    children: [
                        Widget.Button({
                            child: Widget.Label({
                                label: '🞁',
                                class_name: "task-up-label",
                            }),
                            class_name: `task-up ${i % 2 === 0 ? "even-scroll" : "odd-scroll"} ${i === 0 ? "task-up-disabled" : ""}`,
                            on_clicked: () => {
                                if (i > 0) {
                                    const temp = task_list[i];
                                    task_list.splice(i, 1);
                                    task_list.splice(i - 1, 0, temp);
                                    writeUpdate()
                                }
                            }
                        }),
                        Widget.Button({
                            child: Widget.Label({
                                label: '🞃',
                                class_name: "task-down-label",
                            }),
                            class_name: `task-down ${i % 2 === 0 ? "even-scroll" : "odd-scroll"} ${i === task_list.length - 1 ? "task-down-disabled" : ""}`,
                            on_clicked: () => {
                                if (i < task_list.length - 1) {
                                    const temp = task_list[i];
                                    task_list.splice(i, 1);
                                    task_list.splice(i + 1, 0, temp);
                                    writeUpdate()
                                }
                            }
                        }),
                    ]
                }),
                Widget.Button({
                    child: Widget.Label({
                        label: '✎',
                        class_name: "task-edit-label",
                    }),
                    class_name: `task-edit ${i % 2 === 0 ? "even-scroll" : "odd-scroll"}`,
                    on_clicked: () => {
                        entry.text = task
                        entry.grab_focus()
                        task_list.splice(i, 1)
                        writeUpdate()
                    }
                }),
                Widget.Label({
                    label: task,
                    class_name: `task-label ${i % 2 === 0 ? "even-scroll" : "odd-scroll"}`,
                    truncate: 'none',
                    justification: 'left',
                    wrap: true,
                    useMarkup: true,
                })]
        }),
        end_widget: Widget.Box({ // Wrap delete button in a Box for right alignment
            hpack: "end", // Set hpack to "end" for right alignment
            children: [
                Widget.Button({
                    child: Widget.Label({
                        label: '✕', //⨂
                        class_name: "task-delete-label",
                    }),
                    class_name: `task-delete ${i % 2 === 0 ? "even-scroll" : "odd-scroll"}`,
                    on_clicked: () => {
                        task_list.splice(i, 1);
                        writeUpdate()
                    }
                }),
            ]
        }),
    }))
}

const list = Widget.Box({
    vertical: true,
    children: tasks_display(),
})

const entry = Widget.Entry({
    hexpand: true,
    class_name: "tasks-entry",

    on_accept: () => {
        if (entry.text === "") {
            return
        }
        task_list.unshift(`${entry.text}`)
        entry.text = ""
        writeUpdate()
    },

    setup: self => self.hook(App, (_, visible) => {
        // when the app shows up
        if (visible) {
            entry.text = ""
            entry.grab_focus()
        }
    }),
})

export const tasks = () => {
    return Widget.Box({
        class_name: "tasks",
        vertical: true,
        vexpand: true,
        children: [
            Widget.Scrollable({
                vexpand: true,
                // hscroll: "never",
                class_name: "tasks-scroll",
                child: list,
            }),
            Widget.Box({
                class_name: "tasks-entry",
                children: [refresh,entry],
            }),
        ],
    })
}