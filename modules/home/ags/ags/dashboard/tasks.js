let task_list = []

Utils.readFileAsync('/home/adam/.cache/ags/task_list.txt').then((data) => {
    task_list = data.split("\n")
    list.children = tasks_display(task_list)
}).catch(err => print(err))

const refresh = Widget.Button({
    class_name: "task-refresh",
    label: "↻",
    on_clicked: () => {
        Utils.readFileAsync('/home/adam/.cache/ags/task_list.txt').then((data) => {
            task_list = data.split("\n")
            list.children = tasks_display(task_list)
        }).catch(err => print(err))
    }
})

const tasks_display = (task_list) => {

    if (task_list.length === 0 || task_list[0] === "") {
        return [];
    }

    return task_list.map((task, i) => Widget.CenterBox({
        class_name: `${i % 2 === 0 ? "even-scroll" : "odd-scroll"}`,
        hpack: "fill",
        start_widget: Widget.Box({
            children: [
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
                        list.children = tasks_display(task_list)
                        Utils.writeFile(task_list.join("\n"), '/home/adam/.cache/ags/task_list.txt').catch(err => print(err))
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
                        list.children = tasks_display(task_list);
                        Utils.writeFile(task_list.join("\n"), '/home/adam/.cache/ags/task_list.txt').catch(err => print(err));
                    }
                }),
            ]
        }),
    }))
}

const list = Widget.Box({
    vertical: true,
    children: tasks_display(task_list),
})

const entry = Widget.Entry({
    hexpand: true,
    class_name: "tasks-entry",

    on_accept: () => {
        if (entry.text === "") {
            return
        }
        task_list.unshift(`${entry.text}`)
        list.children = tasks_display(task_list)
        entry.text = ""
        Utils.writeFile(task_list.join("\n"), '/home/adam/.cache/ags/task_list.txt').catch(err => print(err))
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