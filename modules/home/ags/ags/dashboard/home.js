const data = Variable([])

const gitSquare = i => Widget.Box({
    class_name: data.bind().as(data => {
        if (data.length !== 0 && i < data.length) {
            if (data[i] === 0) {
                return "git-square git-no-contributions"
            } else {
                return `git-square git-1-contribution`
            }
        } else {
            return "git-square git-loading"
        }
    }),
})

const format = j => Widget.Box({
    vertical: true,
    children: Array(2).fill(0).map((_, i) => gitSquare(j + i)),
    // children: Array(7).fill(0).map((_, i) => gitSquare(j + i)),
})

const gitList = Array(5).fill(0).map((_, j) => format(j * 7))
// const gitList = Array(52).fill(0).map((_, j) => format(j*7))

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

    // print(list)

    // data.value = (list)
}).catch(console.error)