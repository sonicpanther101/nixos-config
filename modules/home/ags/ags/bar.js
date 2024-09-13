const hyprland = await Service.import("hyprland")
const mpris = await Service.import("mpris")
const audio = await Service.import("audio")
const battery = await Service.import("battery")
const systemtray = await Service.import("systemtray")

const date = Variable("", {
    poll: [60000, 'date "+ %A the %eblank of %B"', out => out.replace("blank", nth(day))],
})

const day = Variable("", {
    poll: [60000, 'date "+%e"', out => parseInt(out)],
})

const nth = (d) => {
    if (d > 3 && d < 21) return 'th';
    switch (d % 10) {
        case 1: return "st";
        case 2: return "nd";
        case 3: return "rd";
        default: return "th";
    }
};

const time = Variable("", {
    poll: [60000, 'date "+ %l:%M %p"'],
})

// widgets can be only assigned as a child in one container
// so to make a reuseable widget, make it a function
// then you can simply instantiate one by calling it

const monitor_name = hyprland.active.monitor.name

const monitor_scale = (monitor_name) => {
    if (monitor_name !== "eDP-1") {
        return 1
    } else {
        return 1.9
    }
}

function StartButton() {

    const menu = Widget.Menu({
        children: [
            Widget.MenuItem({
                label: 'Session',
                submenu: Widget.Menu({
                    children: [
                        Widget.MenuItem({
                            label: 'Sleep',
                            on_activate: () => Utils.execAsync(['my-sleep']),
                        }),
                        Widget.MenuItem({
                            label: 'Power Off',
                            on_activate: () => Utils.execAsync(['my-shutdown']),
                        }),
                        Widget.MenuItem({
                            label: 'Reboot',
                            on_activate: () => Utils.execAsync(['reboot']),
                        }),
                    ]
                }),
            }),
            Widget.MenuItem({
                label: 'Start Linewize',
                on_activate: () => Utils.execAsync(['my-linewize']),
                visible: battery.bind("available"),
            }),
            Widget.MenuItem({
                label: 'Restart AGS',
                on_activate: () => Utils.execAsync(['my-ags']),
                visible: battery.bind("available"),
            }),
            Widget.MenuItem({
                label: 'Change Wallpaper',
                // on_activate: () => Utils.execAsync(['wallpaper-picker']),
            }),
            Widget.MenuItem({
                label: 'Rotate Screen',
                submenu: Widget.Menu({
                    children: [
                        Widget.MenuItem({
                            label: 'Upright',
                            on_activate: () => Utils.execAsync(['hyprctl', 'keyword', 'monitor', `${hyprland.active.monitor.name},preferred,auto,${monitor_scale(monitor_name)},transform,0`]),
                        }),
                        Widget.MenuItem({
                            label: 'Left side up',
                            on_activate: () => Utils.execAsync(['hyprctl', 'keyword', 'monitor', `${hyprland.active.monitor.name},preferred,auto,${monitor_scale(monitor_name)},transform,1`]),
                        }),
                        Widget.MenuItem({
                            label: 'Upside down',
                            on_activate: () => Utils.execAsync(['hyprctl', 'keyword', 'monitor', `${hyprland.active.monitor.name},preferred,auto,${monitor_scale(monitor_name)},transform,2`]),
                        }),
                        Widget.MenuItem({
                            label: 'Right side up',
                            on_activate: () => Utils.execAsync(['hyprctl', 'keyword', 'monitor', `${hyprland.active.monitor.name},preferred,auto,${monitor_scale(monitor_name)},transform,3`]),
                        }),
                        Widget.MenuItem({
                            label: 'Rotate 90° clockwise',
                            on_activate: () => {
                                const currentRotation = Utils.exec(`bash -c "hyprctl monitors | grep 'transform' | tail -c 2"`);
                                const command = `hyprctl keyword monitor ${hyprland.active.monitor.name},preferred,auto,${monitor_scale(monitor_name)},transform,${String((parseInt(currentRotation) + 1) % 4)}`;
                                Utils.execAsync(command);
                            },
                        }),
                        Widget.MenuItem({
                            label: 'Rotate 90° counterclockwise',
                            on_activate: () => {
                                const currentRotation = Utils.exec(`bash -c "hyprctl monitors | grep 'transform' | tail -c 2"`);
                                const command = `hyprctl keyword monitor ${hyprland.active.monitor.name},preferred,auto,${monitor_scale(monitor_name)},transform,${String((parseInt(currentRotation) + 3) % 4)}`;
                                Utils.execAsync(command);
                            },
                        }),
                        Widget.MenuItem({
                            label: 'Rotate 180°',
                            on_activate: () => {
                                const currentRotation = Utils.exec(`bash -c "hyprctl monitors | grep 'transform' | tail -c 2"`);
                                const command = `hyprctl keyword monitor ${hyprland.active.monitor.name},preferred,auto,${monitor_scale(monitor_name)},transform,${String((parseInt(currentRotation) + 2) % 4)}`;
                                Utils.execAsync(command);
                            },
                        }),
                    ]
                }),
            }),
            Widget.MenuItem({
                label: 'Gemini UI',
                on_activate: () => Utils.execAsync(["ags", "-t", "gemini-ui"]),
            })
        ],
    });

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

    const button = Widget.Button({
        class_name: "start-button",
        child: Widget.Label(''),
        on_primary_click: (button) => {
            Utils.execAsync(["ags", "-t", "dashboard"])
            Utils.readFileAsync('/home/adam/.cache/ags/dashboard_status.txt').then((data) => {
                Utils.writeFile((!stringToBooleanMap(data)).toString(), '/home/adam/.cache/ags/dashboard_status.txt').catch(err => print(err))
            }).catch(err => print(err))
        },
        on_middle_click: () => Utils.execAsync(["ags", "-t", "applauncher"]),
        on_secondary_click: (_, event) => menu.popup_at_pointer(event),
    })

    const monitorButton = Utils.monitorFile('/home/adam/.cache/ags/dashboard_status.txt', (file, event) => {
        if (event === 1) {
            button.toggleClassName("start-button-with-dashboard-open", Utils.readFile(file) === 'true')
        }
    })

    return button
}

function Workspaces() {

    const workspaceIcon = {
        1: "",
        2: "",
        3: "",
        4: "",
        5: "󰙯",
        6: "",
        7: "",
        8: " ",
        9: "",
    }

    const workspaceButton = (i) => Widget.Button({
        class_name: "ws-button empty",
        on_primary_click: () => hyprland.messageAsync(`dispatch workspace ${i}`),
        child: Widget.Label({
            label: `${workspaceIcon[i]}`,
            class_name: "ws-button-label"
        })
    }).hook(hyprland, (button) => {
        button.toggleClassName("empty", (hyprland.getWorkspace(i)?.windows || 0) === 0);
        button.toggleClassName("occupied", (hyprland.getWorkspace(i)?.windows || 0) > 0);
        button.toggleClassName("active", hyprland.active.workspace.id === i);
    });

    const buttons = Array.from({ length: 9 }, (_, i) => i + 1).map(i => workspaceButton(i));

    return Widget.EventBox({
        onScrollUp: () => dispatch('+1'),
        onScrollDown: () => dispatch('-1'),
        class_name: "workspaces",
        child: Widget.Box({
            children: buttons,
        }),
    })
}


function ClientTitle() {
    return Widget.Label({
        class_name: "client-title",
        label: hyprland.active.client.bind("title"),
    })
}


function Clock() {
    return Widget.Label({
        class_name: "clock",
        tooltip_text: date.bind(),
        label: time.bind(),
    })
}


let currentLength = 0; // Store the current length
Utils.watch(0, mpris, "player-changed", () => {
    if (mpris.players[0]) {
        const { length } = mpris.players[0];
        currentLength = length === -1 ? 0 : length;
    } else {
        currentLength = 0;
    }
});

const media_background = Variable(0, {
    poll: [2000, "playerctl position", out => {
        if (currentLength === 0 || parseInt(out) === 0 || parseInt(out) / currentLength === Infinity) {
            return ""
        } else {
            return `background: linear-gradient(90deg, rgba(0,0,0,0.7) ${100 * parseInt(out) / currentLength}%, rgba(0,0,0,0) ${(100 * parseInt(out) / currentLength) + 10}%);`
        }
    }]
})

function Media() {
    const labele = Utils.watch("", mpris, "player-changed", () => {
        if (mpris.players[0]) {
            const { track_artists, track_title, play_back_status } = mpris.players[0]
            if (track_title === "") {
                return ""
            } else if (track_artists[0] === "") {
                if (play_back_status === "Playing") {
                    return ` ${track_title}`
                } else if (play_back_status === "Paused") {
                    return ` ${track_title}`
                } else if (play_back_status === "Stopped") {
                    return `⯀ ${track_title}`
                }
            } else if (play_back_status === "Playing") {
                return ` ${track_title} - ${track_artists.join(", ")}`
            } else if (play_back_status === "Paused") {
                return ` ${track_title} - ${track_artists.join(", ")}`
            } else if (play_back_status === "Stopped") {
                return `⯀ ${track_title} - ${track_artists.join(", ")}`
            }
        } else {
            return ""
        }
    })

    return Widget.Button({
        class_name: "media",
        visible: Utils.watch(false, mpris, "player-changed", () => {
            if (mpris.players[0]) {
                const { track_artists, track_title, play_back_status } = mpris.players[0]
                if (track_title === "") {
                    //media_background.startPoll()
                    return false
                } else {
                    //media_background.stopPoll()
                    return true
                }
            } else {
                //media_background.startPoll()
                return false
            }
        }),
        on_primary_click: () => mpris.getPlayer("")?.playPause(),
        on_scroll_up: () => mpris.getPlayer("")?.next(),
        on_scroll_down: () => mpris.getPlayer("")?.previous(),
        css: media_background.bind(),
        child: Widget.Box({
            children: [
                Widget.Label({
                    label: labele,
                    truncate: 'end',
                    maxWidthChars: 70,
                }),
                Widget.Box({
                    visible: Utils.watch(false, mpris, "player-changed", () => {
                        if (mpris.players[0]) {
                            const { cover_path } = mpris.players[0]
                            if (cover_path === "") {
                                return false
                            } else {
                                return true
                            }
                        } else {
                            return false
                        }
                    }),
                    class_name: "album-cover",
                    vpack: 'center',
                    css: Utils.watch("", mpris, "player-changed", () => {
                        if (mpris.players[0]) {
                            const { cover_path } = mpris.players[0]

                            if (cover_path === "") {
                                return ""
                            } else {
                                return `background-image: url('${cover_path}');`
                            }
                        } else {
                            return ""
                        }
                    }),
                })
            ],
        }),
    })
}


function Volume() {

    const icons = {
        101: "overamplified",
        67: "high",
        34: "medium",
        1: "low",
        0: "muted",
    }

    function getIcon() {
        const icon = audio.speaker.is_muted ? 0 : [101, 67, 34, 1, 0].find(
            threshold => threshold <= audio.speaker.volume * 100)

        return `audio-volume-${icons[icon]}-symbolic`
    }

    const icon = Widget.Icon({
        icon: Utils.watch(getIcon(), audio.speaker, getIcon),
        class_name: "volume-icon",
    })

    const label = Widget.Label({
        class_name: "volume-label"
    }).hook(audio.speaker, self => {
        const vol = audio.speaker.volume * 100;
        self.label = ` ${Math.round(vol)}%`;
    })

    function audioChange(x) {
        let rounded = Math.round(audio.speaker.volume * 100)
        if (rounded % 2 === 0) {
            if (x > 0 && rounded >= 98) {
                audio.speaker.volume = 1
            } else {
                audio.speaker.volume += (x)
            }
        } else {
            audio.speaker.volume += (x / 2)
        }
    }

    const volumeIndicator = Widget.Button({
        class_name: "volume",
        on_primary_click: () => audio.speaker.is_muted = !audio.speaker.is_muted,
        on_secondary_click: () => Utils.execAsync(["pavucontrol"]),
        on_scroll_up: () => audioChange(0.02),
        on_scroll_down: () => audioChange(-0.02),
        child: Widget.Box({
            children: [icon, label],
        }),
    })

    return Widget.Box({
        class_name: "volume-box",
        children: [volumeIndicator],
    })
}


function round1DP(num) {
    return Math.round((num - Number.EPSILON) * 10) / 10
}

function secondsToHms(d) {
    d = Number(d);
    var h = Math.floor(d / 3600);
    var m = Math.floor(d % 3600 / 60);

    var hDisplay = h > 0 ? h + (h == 1 ? " hour, " : " hours, ") : "";
    var mDisplay = m > 0 ? m + (m == 1 ? " minute" : " minutes") : "";
    return hDisplay + mDisplay;
}

function charginG(charging) {
    if (charging) {
        return "fully charged"
    } else {
        return "dead"
    }
}

function chargeD(charged, timeLeft, charging) {
    if (charged) {
        return "fully charged"
    } else {
        return `${secondsToHms(timeLeft)} till ${charginG(charging)}`
    }
}

function checkBattery(batteryUsed) {
    if (batteryUsed) {
        return "margin-right: 7px;"
    } else {
        return ""
    }
}

function chargiNG(value) {
    if (value) {
        return ""
    } else {
        return "dis"
    }
}

function BatteryLabel() {
    return Widget.Box({
        class_name: "battery",
        css: checkBattery(battery.bind("available")),
        visible: battery.bind("available"),
        tooltip_text: Utils.merge([battery.bind("energy"), battery.bind("energy-full"), battery.bind("energy-rate"), battery.bind("charging"), battery.bind("charged"), battery.bind("time-remaining")],
                                (energy, energyFull, energyRate, charging, charged, timeLeft) => {
            return `${round1DP(energy)}Wh/${round1DP(energyFull)}Wh | ${round1DP(energyRate)}W ${chargiNG(charging)}charge rate | ${chargeD(charged, timeLeft, charging)}`
        }),
        children: [
            Widget.Icon({
                class_name: "battery-icon",
                icon: battery.bind('icon_name'),
                css: checkBattery(battery.bind("available")),
            }),

            Widget.Label({
                label: battery.bind("percent").as(percent => {
                    return `${percent}%`;
                }),
            }),
        ],
    })
}


function SysTray() {
    const items = systemtray.bind("items")
        .as(items => items.map(item => Widget.Button({
            child: Widget.Icon({ icon: item.bind("icon") }),
            class_name: "tray-items",
            on_secondary_click: (_, event) => item.activate(event),
            on_primary_click: (_, event) => item.openMenu(event),
            tooltip_markup: item.bind("tooltip_markup"),
        })))

    return Widget.Box({
        class_name: "tray",
        children: items,
    })
}


// layout of the bar
function Left() {
    return Widget.Box({
        children: [
            StartButton(),
            Workspaces(),
            //ClientTitle(),
        ],
    })
}

function Center() {
    return Widget.Box({
        children: [
            Clock(),
        ],
    })
}

function Right() {
    return Widget.Box({
        hpack: "end",
        class_name: "Right",
        children: [
            Media(),
            Volume(),
            BatteryLabel(),
            SysTray(),
        ],
    })
}

export function Bar(monitor = 0) {
    return Widget.Window({
        name: `bar-${monitor}`, // name has to be unique
        class_name: "bar",
        monitor,
        anchor: ["top", "left", "right"],
        exclusivity: "exclusive",
        child: Widget.CenterBox({
            start_widget: Left(),
            center_widget: Center(),
            end_widget: Right(),
        }),
    })
}

export const monitorNum = hyprland.monitors.length;