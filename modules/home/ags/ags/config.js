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

App.config({
    style: "./styles/notificationPopups.css",
    windows: [Array.from({ length: monitorNum }, (_, i) => i).map(i => NotificationPopups(i))],
})

import { ClipBoard } from "./clipboard.js"

App.config({
    style: './styles/clipboard.css',
    windows: () => [
        ClipBoard(),
    ],
});

export { }

Utils.monitorFile(
    // directory that contains the scss files
    `/home/adam/nixos-config/modules/home/ags/ags/styles`,

    // reload function
    function () {
        // css files
        const css1 = `/home/adam/nixos-config/modules/home/ags/ags/styles/applauncher.css`
        const css2 = `/home/adam/nixos-config/modules/home/ags/ags/styles/bar.css`
        const css3 = `/home/adam/nixos-config/modules/home/ags/ags/styles/dashboard.css`
        const css4 = `/home/adam/nixos-config/modules/home/ags/ags/styles/gemini-ui.css`
        const css5 = `/home/adam/nixos-config/modules/home/ags/ags/styles/notificationPopups.css`
        const css6 = `/home/adam/nixos-config/modules/home/ags/ags/styles/clipboard.css`

        // reset, apply
        App.resetCss()
        App.applyCss(css1)
        App.applyCss(css2)
        App.applyCss(css3)
        App.applyCss(css4)
        App.applyCss(css5)
        App.applyCss(css6)
    },
)