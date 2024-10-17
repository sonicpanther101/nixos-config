const WINDOW_NAME = "gemini-ui"
const API_KEY = "AIzaSyB-8_m7kiuNGgfNs_lns0ILwrrERfqfhjM"

function removeEmojis(text) {
    // Regular expression to match emojis
    const emojiRegex = /[\u203C-\u32FF\uDBFF-\uDFFF]/g;

    // Replace emojis with empty strings
    return text.replace(emojiRegex, '');
}

function stripMarkdown(input) {
    let output = removeEmojis(input);

    // Remove headers (#) and replace with <br>
    output = output.replace(/#{1,6}\s*/g, "<br>");

    // Remove bold (**) and (__) formatting
    output = output.replace(/\*\*(.*?)\*\*|__(.*?)__/g, "$1$2");

    // Remove italic (*) and (_) formatting
    output = output.replace(/\*(.*?)\*|_(.*?)_/g, "$1$2");

    // Remove inline code (``) and replace with <br>
    output = output.replace(/`(.*?)`/g, "$1");

    // Remove links [text](url) and replace with <br>
    output = output.replace(/\[.*?\]\(.*?\)/g, "<br>");

    // Remove images ![alt](url) and replace with <br>
    output = output.replace(/![.*?]\(.*?\)/g, "<br>");

    // Remove blockquotes (>) and replace with <br>
    output = output.replace(/^>\s*/gm, "<br>");

    // Remove lists (*) and (-) and replace with <br>
    output = output.replace(/^\s*[\*\-]\s*/gm, "<br>");

    // Replace multiple new lines with a single <br>
    output = output.replace(/(<br>\s*)+/g, "<br>");

    // Replace <br> with \n
    output = output.replace(/<br>/g, "\n");

    return output.trim();
}

const geminiUI = ({ spacing = 0, width = 370, height = 730 } = {}) => {

    const message_box = (messages) => {
        if (messages.length === 0) {
            return [];
        }

        return messages.slice(2).map((message, i) => Widget.Label({
            label: message["text"],
            truncate: 'none',
            justification: 'left',
            wrap: true,
            useMarkup: true,
            class_name: `message ${i % 2 === 0 ? "right-message" : "left-message"}`,
        }))
    }

    const systemPrompt = Utils.readFile('/home/adam/.cache/ags/systemPrompt.txt')

    let messages = []

    messages.push({ 'text': systemPrompt })
    messages.push({ 'text': "Got it! I will stick to your rules and remember everything you tell me." })

    // container holding the past messages
    const list = Widget.Box({
        vertical: true,
        children: message_box(messages),
        spacing,
    })

    // text entry
    const entry = Widget.Entry({
        hexpand: true,
        vexpand: true,
        class_name: "gemini-entry",
        css: `margin-bottom: ${spacing}px;`,

        // to send to gemini on Enter
        on_accept: () => {
            messages.push({'text': entry.text})
            list.children = message_box(messages)
            entry.text = ""

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
                let message = data["candidates"][0]["content"]["parts"][0]["text"]
                    messages.push({ 'text': stripMarkdown(message)})
                list.children = message_box(messages)
            }).catch(err => print(err));
        },
    })

    return Widget.Box({
        vertical: true,
        class_name: "gemini-ui-window",
        children: [
            // Widget.Label({
            //     label: "Gemini", // Title
            // }),

            // wrap the list in a scrollable
            Widget.Scrollable({
                class_name: "scroll",
                hscroll: "automatic",
                css: `min-width: ${width}px;`
                    + `min-height: ${height}px;`,
                child: list,
            }),

            Widget.Box({
                vertical: false,
                children: [
                    Widget.Button({
                        class_name: "gemini-reset-button",
                        on_primary_click: () => {
                            messages = []
                            messages.push({ 'text': systemPrompt })
                            messages.push({ 'text': "Got it! I will stick to your rules and remember everything you tell me." })

                            list.children = message_box(messages)
                        },
                        child: Widget.Label({
                            label: "↻",
                            class_name: "gemini-reset-button-label",
                        }),
                    }),
                    entry
                ]
            })
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
// // const RegularWindow = Widget.subclass < typeof Gtk.Window, Gtk.Window.ConstructorProperties> (Gtk.Window)

// export const GeminiUI = new Gtk.Window({
//     name: WINDOW_NAME,
//     // setup: self => self.keybind("Escape", () => {
//     //     App.closeWindow(WINDOW_NAME)
//     // }),
//     visible: false,
//     // class_name: "gemini-ui",
//     hexpand: true,
//     vexpand: true,
//     child: geminiUI(),
// })

export const GeminiUI = Widget.Window({
    name: WINDOW_NAME,
    setup: self => self.keybind("Escape", () => {
        App.closeWindow(WINDOW_NAME)
    }),
    visible: false,
    class_name: "gemini-ui",
    keymode: "on-demand",
    anchor: ["right", "bottom"],
    hexpand: true,
    vexpand: true,
    child: geminiUI(),
})