let list = Widget.Box({
    vertical: true,
    children: [
        Widget.Label('food & water'),
        Widget.Label('comfy clothes'),
        Widget.Label('lights correct'),
        Widget.Label('correct equipment'),
        Widget.Label('foot thing'),
        Widget.Label('music set up'),
        Widget.Label('break activity set up'),
        Widget.Label('ags study timer on'),
    ]
})

export const study = () => {
    return Widget.Box({
        class_name: "study",
        children: [
            list
        ]
    })
}