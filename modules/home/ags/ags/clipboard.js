const { Box, Label, ListBox, Icon, Scrollable, Window } = Widget;
const { execAsync, exec } = Utils;

// I'm not using async here because I want the performance of the script to be obvious
const clipboard = exec(`${App.configDir}/clipboard.sh`);

const ClipBoardItem = value => Widget.Button({
    attribute: { value },
    child: Box({
        css: `
            border: 2px solid @accent_bg_color;
            padding: 5px;
        `,
        child: value.startsWith('img:') ?
            Icon({
                icon: value.replace('img:', ''),
                size: 200,
            }) :

            Label({
                label: value,
                truncate: 'end',
                max_width_chars: 100,
            }),
    })
});

const decodeItem = (index) => {
    // Also using exec here to show how slow this is
    // It also gives this error when using async: "Lib.Error g-unix-error-quark: Too many open files"
    const out = exec([
        'bash', '-c', `cliphist list | grep ${index} | cliphist decode`,
    ]);
    return out;
};

let data = clipboard.split('\n').forEach((item) => {
        print(item);
        if (item.includes('img')) {
            return item;
        }
        else {
            return decodeItem(item);
        }
});


export const ClipBoard = () => {
    let clipboardItems = [];

    // container holding the buttons
    const list = Widget.Box({
        vertical: true,
        children: clipboardItems,
    })

    const entry = Widget.Entry({
        hexpand: true,
        css: `margin-bottom: 10px;`,

        // to launch the first item on Enter
        on_accept: () => {
            // make sure we only consider visible (searched for) applications
            const results = applications.filter((item) => item.visible);
            if (results[0]) {
                App.toggleWindow(WINDOW_NAME)
                results[0].attribute.app.launch()
            }
        },

        // filter out the list
        on_change: ({ text }) => clipboardItems.forEach(item => {
            item.visible = item.attribute.value.match(text ?? "")
        }),
    })

    return Window({
        name: 'clipboard',
        setup: self => self.keybind("Escape", () => {
            App.closeWindow('clipboard')
        }),
        visible: false,
        class_name: "clipboard-window",
        keymode: "exclusive",
        child: Box({
            vertical: true,
            children: [
                entry,

                Scrollable({
                    hscroll: 'never',
                    vscroll: 'always',
                    child: Box({
                        vertical: true,
                        children: [list],
                    }),
                }),
            ],
        }),
        setup: self => self.hook(App, (_, windowName, visible) => {
            if (windowName !== 'clipboard')
                return

            // when the applauncher shows up
            if (visible) {
                print(data)
                // clipboardItems = data.map(ClipBoardItem);
                // repopulate()
                entry.text = ""
                entry.grab_focus()
            }
        }),
    });
};