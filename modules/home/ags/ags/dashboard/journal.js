let journal_list = []
let gistID = ""
let token = ""

Utils.readFileAsync(`/home/adam/.cache/ags/secrets.txt`).then((secrets) => {
    const secretsList = secrets.split("\n")
    for (const secret of secretsList) {
        const [name, value] = secret.split(":")
        if (name === "journal_gist_id") {
            gistID = value
        } else if (name === "token") {
            token = value
        }
    }
    if (gistID === "") {
        print("journal directory not found in secrets.txt")
        return
    } else if (token === "") {
        print("token not found in secrets.txt")
        return
    }
    readUpdate()
}).catch(err => print(err))

const refresh = Widget.Button({
    class_name: "journal-refresh",
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

        const data = JSON.parse(out)["files"]["journal.txt"]["content"]

        Utils.writeFile(data, `/home/adam/.cache/ags/journal.txt`).catch(err => print(err))

        let tempList = data.split("\n")
        if (tempList.length % 3 !== 0) {
            print("journal.txt is not formatted correctly")
            return
        }
        for (let i = 0; i < tempList.length; i += 3) {
            journal_list.push({
                date: tempList[i],
                heading: tempList[i + 1],
                content: tempList[i + 2]
            });
        }
        list.children = journals_display()
    }).catch(err => print(err))
}

function writeUpdate() {
    list.children = journals_display()
    Utils.writeFile(journal_list.join("\n"), `/home/adam/.cache/ags/journal.txt`).catch(err => print(err))
    Utils.execAsync(['bash', '-c', `curl -L \
  -X PATCH \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${token}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/gists/${gistID} \
  -d '{"description":"Updated Gist","files":{"journal.txt":{"content":"${journal_list.flatMap(Object.values).map(journal => journal
        .replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/'/g, "\\'")).join("\\n")}"}}}'`]).catch(err => print(err));
}

const readPoller = Variable("", {
    poll: [60000, () => readUpdate()]
})

const journals_display = () => {

    journal_list = journal_list.filter(journal => journal !== "");

    if (journal_list.length === 0) {
        return [];
    }

    return journal_list.map((journal, i) => Widget.CenterBox({
        class_name: i % 2 === 0 ? "even-scroll" : "odd-scroll",
        hpack: "fill",
        start_widget: Widget.Box({
            children: [
                Widget.Button({
                    child: Widget.Label({
                        label: '✎',
                        class_name: "journal-edit-label",
                    }),
                    class_name: `journal-edit ${i % 2 === 0 ? "even-scroll" : "odd-scroll"}`,
                    on_clicked: () => {
                        entry.text = journal.content
                        headingEntry.text = journal.heading
                        headingEntry.grab_focus()
                        journal_list.splice(i, 1)
                        writeUpdate()
                    }
                }),
                Widget.Label({
                    label: journal.heading,
                    class_name: `journal-label ${i % 2 === 0 ? "even-scroll" : "odd-scroll"}`,
                    truncate: 'none',
                    justification: 'left',
                    wrap: true,
                    useMarkup: true,
                })
            ]
        }),
        end_widget: Widget.Box({ // Wrap delete button in a Box for right alignment
            hpack: "end", // Set hpack to "end" for right alignment
            children: [
                Widget.Label({
                    label: journal.date,
                    class_name: `journal-label ${i % 2 === 0 ? "even-scroll" : "odd-scroll"}`,
                    truncate: 'none',
                    justification: 'left',
                    wrap: true,
                    useMarkup: true,
                }),
                Widget.Button({
                    child: Widget.Label({
                        label: '✕', //⨂
                        class_name: "journal-delete-label",
                    }),
                    class_name: `journal-delete ${i % 2 === 0 ? "even-scroll" : "odd-scroll"}`,
                    on_clicked: () => {
                        journal_list.splice(i, 1);
                        writeUpdate()
                    }
                }),
            ]
        }),
    }))
}

const list = Widget.Box({
    vertical: true,
    children: journals_display(),
})

const entry = Widget.Entry({
    hexpand: true,
    class_name: "journals-entry",

    on_accept: () => {
        if (entry.text === "" || headingEntry.text === "") {
            return
        }
        journal_list.unshift({
            // date: new Date().toLocaleString(),
            date: new Date().toLocaleDateString(),
            heading: headingEntry.text,
            content: entry.text
        })
        entry.text = ""
        headingEntry.text = ""
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

const headingEntry = Widget.Entry({
    hexpand: true,
    class_name: "journals-entry",
})

export const journal = () => {
    return Widget.Box({
        class_name: "journals",
        vertical: true,
        vexpand: true,
        children: [
            Widget.Scrollable({
                vexpand: true,
                // hscroll: "never",
                class_name: "journals-scroll",
                child: list,
            }),
            Widget.Box({
                vertical: true,
                class_name: "journals-entry",
                children: [
                    Widget.Box({
                        class_name: "journals-entry",
                        children: [Widget.Label({label: "Heading:"}), headingEntry],
                    }),
                    Widget.Box({
                        class_name: "journals-entry",
                        children: [refresh, entry],
                    })
                ],
            }),
        ],
    })
}