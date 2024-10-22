const data = Variable([])

const gitSquare = i => Widget.Box({
    class_name: "git-square",
    css: data.bind().as(data => {
        if (data.length !== 0 && i < data.length) {
            print(data[i])
            if (data[i] === 0) {
                return "background-color: rgb(255, 0, 0);"
            } else {
                return `background-color: rgba(0, 255, 0, ${Math.min(data[i], 1)});`
            }
        } else {
            return "background-color: rgb(0, 255, 0);"
        }
    }),
    // css: `background-color: rgba(0, 255, 0, 1);`,
    // css: `background-color: rgba(0, 255, 0, ${Math.min(i / 350, 1)});`,
    // css: `background-color: rgba(0, 255, 0, ${Math.min(data[i] / 10, 1)});`,
})

const format = j => Widget.Box({
    vertical: true,
    children: Array(7).fill(0).map((_, i) => gitSquare(j + i)),
})

const gitList = Array(52).fill(0).map((_, j) => format(j*7))

export const home = Widget.Box({
    class_name: "home",
    children: [
        Widget.Label({
            label: data.bind().as(data => {
                return data.toString()
            }),
            class_name: "git-label",
        }),
        Widget.Box({
            class_name: "git-list",
            vertical: false,
            children: gitList,
        }),
    ],
})

Utils.fetch('https://github-contributions-api.jogruber.de/v4/sonicpanther101').then(response => response.json()).then(out => {
    let list = []

    for (let i = 0; i < out.contributions.length; i++) {
        list.push(out.contributions[i].count)
    }

    data.setValue(list)
}).catch(console.error)