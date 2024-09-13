const WINDOW_NAME = "gemini-ui"
const API_KEY = "AIzaSyB-8_m7kiuNGgfNs_lns0ILwrrERfqfhjM"

const geminiUI = ({ spacing = 12, width = 500, height = 500 } = {}) => {

    const message_box = (messages) => {
        if (messages.length === 0) {
            return [];
        }

        return messages.map((message, i) => Widget.Label({
            label: message["text"],
            truncate: 'none',
            justification: 'left',
            wrap: true,
            useMarkup: true,
            class_name: `message ${i % 2 === 0 ? "right-message" : "left-message"}`,
        }))
    }

    let messages = []

    // container holding the past messages
    const list = Widget.Box({
        vertical: true,
        children: message_box(messages),
        spacing,
    })

    // text entry
    const entry = Widget.Entry({
        hexpand: true,
        css: `margin-bottom: ${spacing}px;`,

        // to send to gemini on Enter
        on_accept: () => {
            messages.push({'text': `${entry.text}`})
            list.children = message_box(messages)

            Utils.fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${API_KEY}`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    contents: [{
                        parts: [
                            messages
                        ]
                    }]
                }),
            })
            .then(response => response.json())
                .then(data => {
                console.log(data);
                let message = data["candidates"][0]["content"]["parts"][0]["text"]
                console.log(message);
                messages.push({'text': `${message}`})
                list.children = message_box(messages)
                entry.text = ""
            }).catch(err => print(err));
        },
    })

    return Widget.Box({
        vertical: true,
        class_name: "gemini-ui-window",
        children: [
            Widget.Label({
                label: "Gemini", // Title
            }),

            // wrap the list in a scrollable
            Widget.Scrollable({
                class_name: "scroll",
                hscroll: "automatic",
                css: `min-width: ${width}px;`
                    + `min-height: ${height}px;`,
                child: list,
            }),

            entry,
        ],
        setup: self => self.hook(App, (_, visible) => {
            // when the app shows up
            if (visible) {
                entry.text = ""
                entry.grab_focus()
            }
        }),
    })
}

// import Gtk from "gi://Gtk?version=3.0"
// const RegularWindow = Widget.subclass < typeof Gtk.Window, Gtk.Window.ConstructorProperties> (Gtk.Window)

export const GeminiUI = Widget.Window({
    name: WINDOW_NAME,
    setup: self => self.keybind("Escape", () => {
        App.closeWindow(WINDOW_NAME)
    }),
    visible: false,
    exclusivity: "exclusive",
    class_name: "gemini-ui",
    keymode: "on-demand",
    hexpand: true,
    vexpand: true,
    child: geminiUI(),
})