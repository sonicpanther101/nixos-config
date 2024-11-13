const { Box, Label, ListBox, Icon, Scrollable, Window } = Widget;
const { exec } = Utils;

// I'm not using async here because I want the performance of the script to be obvious
const clipboard = exec(`${App.configDir}/clipboard.sh`);


const ClipBoard = () => {
    const list = ListBox();

    const makeItem = (key, val) => {
        console.log(key);
        const widget = Box({
            css: `
                border: 2px solid @accent_bg_color;
                padding: 5px;
            `,
            child: val.startsWith('img:') ?
                Icon({
                    icon: val.replace('img:', ''),
                    size: 200,
                }) :

                Label({
                    label: val,
                    truncate: 'end',
                    max_width_chars: 100,
                }),
        });

        list.add(widget);
        list.show_all();
    };

    const decodeItem = (index) => {
        // Also using exec here to show how slow this is
        // It also gives this error when using async: "Lib.Error g-unix-error-quark: Too many open files"
        const out = exec([
            'bash', '-c', `cliphist list | grep ${index} | cliphist decode`,
        ]);
        makeItem(index, out);
    };

    clipboard.split('\n').forEach((item) => {
        if (item.includes('img')) {
            makeItem((item.match('[0-9]+') ?? [''])[0], item);
        }
        else {
            decodeItem(item);
        }
    });

    return Window({
        name: 'clipboard',
        child: Scrollable({
            hscroll: 'never',
            vscroll: 'always',
            child: Box({
                vertical: true,
                children: [list],
            }),
        }),
    });
};

App.config({
    style: './style.css',
    windows: () => [
        ClipBoard(),
    ],
});
