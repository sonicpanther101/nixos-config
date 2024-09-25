import { Bar, monitorNum } from "./bar.js"

App.config({
    style: "./styles/bar.css",
    windows: Array.from({ length: monitorNum }, (_, i) => i).map(i => Bar(i))
})

import { applauncher } from "./applauncher.js"

App.config({
    style: "./styles/applauncher.css",
    windows: [applauncher],
})

import { GeminiUI } from "./gemini-ui.js"

App.config({
    style: "./styles/gemini-ui.css",
    windows: [GeminiUI],
})

import { dashboard } from "./dashboard.js"

Utils.writeFile("false", '/home/adam/.cache/ags/dashboard_status.txt').catch(err => print(err))

App.config({
    style: "./styles/dashboard.css",
    windows: [dashboard()],
})

import { NotificationPopups } from "./notificationPopups.js"

Utils.timeout(100, () => Utils.notify({
    summary: "Notification Popup Example",
    iconName: "info-symbolic",
    body: "Lorem ipsum dolor sit amet, qui minim labore adipisicing "
        + "minim sint cillum sint consectetur cupidatat.",
    actions: {
        "Cool": () => print("pressed Cool"),
    },
}))

App.config({
    style: App.configDir + "/styles/notificationPopups.css",
    windows: [Array.from({ length: monitorNum }, (_, i) => i).map(i => NotificationPopups(i))],
})

export { }

Utils.monitorFile(
    // directory that contains the scss files
    `/home/adam/.config/ags/styles`,

    // reload function
    function () {
        // css files
        const css1 = `/home/adam/.config/ags/styles/applauncher.css`
        const css2 = `/home/adam/.config/ags/styles/bar.css`
        const css3 = `/home/adam/.config/ags/styles/dashboard.css`
        const css4 = `/home/adam/.config/ags/styles/gemini-ui.css`
        const css5 = `/home/adam/.config/ags/styles/notificationPopups.css`

        // reset, apply
        App.resetCss()
        App.applyCss(css1)
        App.applyCss(css2)
        App.applyCss(css3)
        App.applyCss(css4)
        App.applyCss(css5)
    },
)