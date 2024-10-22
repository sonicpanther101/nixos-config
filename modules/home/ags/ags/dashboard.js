const WINDOW_NAME = "dashboard"
const currentDisplay = Variable('home')

import { home } from "./dashboard/home.js"
import { tasks } from "./dashboard/tasks.js"
import { journal } from "./dashboard/journal.js"
import { budget } from "./dashboard/budget.js"
import { events } from "./dashboard/events.js"
import { goals } from "./dashboard/goals.js"
import { life } from "./dashboard/life.js"

const Dashboard = () => {

    const menuItems = ["home", "tasks", "journal", "budget", "events", "goals", "life"]

    const menuItemButtons = () => { 
        return menuItems.map(item => Widget.Button({
            class_name: "dashboard-button",
            child: Widget.Label({
                label: item.charAt(0).toUpperCase() + item.slice(1),
                class_name: "dashboard-menu-item",
            }),
            on_primary_click: () => {
                currentDisplay.value = item
            },
        }))
    }

    const menu = () => { 
        return Widget.Box({
            class_name: "dashboard-menu",
            vertical: true,
            children: [
                Widget.Label({
                    label: "Adam's Dashboard",
                    class_name: "dashboard-menu-label",
                }),
                menuItemButtons()
            ].flat(),
        })
    }

    const Home = () => { 
        return Widget.Box({
            visible: currentDisplay.bind().as(item => item === "home"),
            hexpand: true,
            class_name: "dashboard-home",
            vertical: true,
            children: [
                Widget.Label({
                    label: "Home",
                    class_name: "dashboard-home-label",
                }),
                home,
            ],
        })
    }

    const Tasks = () => {
        return Widget.Box({
            visible: currentDisplay.bind().as(item => item === "tasks"),
            hexpand: true,
            vexpand: true,
            class_name: "dashboard-tasks",
            vertical: true,
            children: [
                Widget.Label({
                    label: "Tasks",
                    class_name: "dashboard-tasks-label",
                }),
                tasks(),
            ],
        })
    }

    const Journal = () => {
        return Widget.Box({
            visible: currentDisplay.bind().as(item => item === "journal"),
            hexpand: true,
            class_name: "dashboard-journal",
            vertical: true,
            children: [
                Widget.Label({
                    label: "Journal",
                    class_name: "dashboard-journal-label",
                }),
                journal(),
            ],
        })
    }

    const Budget = () => {
        return Widget.Box({
            visible: currentDisplay.bind().as(item => item === "budget"),
            hexpand: true,
            class_name: "dashboard-budget",
            vertical: true,
            children: [
                Widget.Label({
                    label: "Budget",
                    class_name: "dashboard-budget-label",
                }),
                budget(),
            ],
        })
    }

    const Events = () => {
        return Widget.Box({
            visible: currentDisplay.bind().as(item => item === "events"),
            hexpand: true,
            class_name: "dashboard-events",
            vertical: true,
            children: [
                Widget.Label({
                    label: "Events",
                    class_name: "dashboard-events-label",
                }),
                events(),
            ],
        })
    }

    const Goals = () => {
        return Widget.Box({
            visible: currentDisplay.bind().as(item => item === "goals"),
            hexpand: true,
            class_name: "dashboard-goals",
            vertical: true,
            children: [
                Widget.Label({
                    label: "Goals",
                    class_name: "dashboard-goals-label",
                }),
                goals,
            ],
        })
    }

    const Life = () => {
        return Widget.Box({
            visible: currentDisplay.bind().as(item => item === "life"),
            hexpand: true,
            class_name: "dashboard-life",
            vertical: true,
            children: [
                Widget.Label({
                    label: "Life",
                    class_name: "dashboard-life-label",
                }),
                life(),
            ],
        })
    }

    const display = Widget.Box({
        class_name: "dashboard-window",
        vertical: true,
        children: [
            Home(),
            Tasks(),
            Journal(),
            Budget(),
            Events(),
            Goals(),
            Life(),
        ],
    })

    return Widget.Box({
        class_name: "dashboard",
        vertical: false,
        children: [
            menu(),
            display,
        ],
    })
}

function stringToBooleanMap(str) {
    const boolMap = {
        'true': true,
        'false': false,
        'yes': true,
        'no': false,
        '1': true,
        '0': false
    };

    return boolMap[str.toLowerCase()] ?? null;
}

export const dashboard = () => {
    return Widget.Window({
        name: WINDOW_NAME,
        setup: self => self.keybind("Escape", () => {
            App.closeWindow(WINDOW_NAME)
            Utils.readFileAsync('/home/adam/.cache/ags/dashboard_status.txt').then((data) => {
                Utils.writeFile((!stringToBooleanMap(data)).toString(), '/home/adam/.cache/ags/dashboard_status.txt').catch(err => print(err))
            }).catch(err => print(err))
        }),
        visible: false,
        exclusivity: "exclusive",
        anchor: ["top", "left", "right", "bottom"],
        class_name: "dashboard-window",
        keymode: "on-demand",
        child: Dashboard(),
    })
}