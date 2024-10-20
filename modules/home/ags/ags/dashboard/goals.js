let goals_list = []
let gistID = ""
let token = ""

Utils.readFileAsync(`/home/adam/.cache/ags/secrets.txt`).then((secrets) => {
    const secretsList = secrets.split("\n")
    for (const secret of secretsList) {
        const [name, value] = secret.split(":")
        if (name === "goals_gist_id") {
            gistID = value
        } else if (name === "token") {
            token = value
        }
    }
    if (gistID === "") {
        print("goals directory not found in secrets.txt")
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
        
        const data = JSON.parse(out)["files"]["goals.txt"]["content"]

        Utils.writeFile(data, `/home/adam/.cache/ags/goals.txt`).catch(err => print(err))
        
        goals_list = data.split("\n")
        list.children = goals_display()
    }).catch(err => print(err))
}

function writeUpdate() {
    list.children = goals_display()
    Utils.writeFile(goals_list.join("\n"), `/home/adam/.cache/ags/goals.txt`).catch(err => print(err))
    Utils.execAsync(['bash', '-c', `curl -L \
  -X PATCH \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${token}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/gists/${gistID} \
  -d '{"description":"Updated Gist","files":{"goals.txt":{"content":"${goals_list.map(task => task
      .replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/'/g, "\\'")).join("\\n")}"}}}'`]).catch(err => print(err));
}

const readPoller = Variable("", {
    poll: [60000, () => readUpdate()]
})

const goals_display = () => {

    goals_list = goals_list.filter(task => task !== "");

    if (goals_list.length === 0) {
        return [];
    }

    return goals_list.map((task, i) => Widget.CenterBox({
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
                                    const temp = goals_list[i];
                                    goals_list.splice(i, 1);
                                    goals_list.splice(i - 1, 0, temp);
                                    writeUpdate()
                                }
                            }
                        }),
                        Widget.Button({
                            child: Widget.Label({
                                label: '🞃',
                                class_name: "task-down-label",
                            }),
                            class_name: `task-down ${i % 2 === 0 ? "even-scroll" : "odd-scroll"} ${i === goals_list.length - 1 ? "task-down-disabled" : ""}`,
                            on_clicked: () => {
                                if (i < goals_list.length - 1) {
                                    const temp = goals_list[i];
                                    goals_list.splice(i, 1);
                                    goals_list.splice(i + 1, 0, temp);
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
                        goals_list.splice(i, 1)
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
                        goals_list.splice(i, 1);
                        writeUpdate()
                    }
                }),
            ]
        }),
    }))
}

const list = Widget.Box({
    vertical: true,
    children: goals_display(),
})

const entry = Widget.Entry({
    hexpand: true,
    class_name: "tasks-entry",

    on_accept: () => {
        if (entry.text === "") {
            return
        }
        goals_list.unshift(`${entry.text}`)
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

const toggleEditMode = Widget.Button({
    class_name: "goals-edit-mode",
    hpack: "end",
    child: Widget.Label({
        label: '✎',
        class_name: "task-edit-label",
    }),
    on_clicked: () => {
        editMode.setValue(!editMode.getValue())
        // entry.grab_focus()
    }
})

const editMode = Variable(true);

const fixer = setTimeout(() => { 
    editMode.setValue(false)
 }, 1000)

export const goals = () => {

    return Widget.Box({
        vertical: true,
        vexpand: true,
        children: editMode.bind().as(editMode => {
            if (editMode === true) {
                return [
                    Widget.Scrollable({
                        vexpand: true,
                        // hscroll: "never",
                        class_name: "tasks-scroll",
                        child: list,
                    }),
                    Widget.Box({
                        class_name: "tasks-entry",
                        children: [refresh, entry],
                    }),
                    toggleEditMode
                ]
            } else {
                return [
                    Widget.Scrollable({
                        vexpand: true,
                        // hscroll: "never",
                        class_name: "tasks-scroll",
                        child: Widget.Label({
                            class_name: "goals-label",
                            label: goals_list.map(task => task.replace("", "- ")).join("\n"),
                        }),
                    }),
                    toggleEditMode
                ]
            }
        }),
    })
}