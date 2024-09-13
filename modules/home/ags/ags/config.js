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

        // reset, apply
        App.resetCss()
        App.applyCss(css1)
        App.applyCss(css2)
        App.applyCss(css3)
        App.applyCss(css4)
    },
)