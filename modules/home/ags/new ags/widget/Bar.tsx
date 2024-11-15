import { App } from "astal/gtk3"
import { Variable, GLib, bind, execAsync } from "astal"
import { Astal, Gtk, Gdk } from "astal/gtk3"
import Hyprland from "gi://AstalHyprland"
import Mpris from "gi://AstalMpris"
import Player from "gi://AstalMpris"
import Battery from "gi://AstalBattery"
import Wp from "gi://AstalWp"
import Network from "gi://AstalNetwork"
import Tray from "gi://AstalTray"

function StartButton() {
    return <button
        className="StartButton"
        onClicked={() => {
            studyMode.set(!studyMode.get())
            studyPaused.set(studyMode.get() ? false : true)
        }}>
        <label label=" " />
    </button>
}

function SysTray() {
    const tray = Tray.get_default()

    return <box>
        {bind(tray, "items").as(items => items.map(item => {
            if (item.iconThemePath)
                App.add_icons(item.iconThemePath)

            const menu = item.create_menu()

            return <button
                tooltipMarkup={bind(item, "tooltipMarkup")}
                onDestroy={() => menu?.destroy()}
                onClickRelease={self => {
                    menu?.popup_at_widget(self, Gdk.Gravity.SOUTH, Gdk.Gravity.NORTH, null)
                }}>
                <icon gIcon={bind(item, "gicon")} />
            </button>
        }))}
    </box>
}

function Wifi() {
    const { wifi } = Network.get_default()

    return <icon
        tooltipText={bind(wifi, "ssid").as(String)}
        className="Wifi"
        icon={bind(wifi, "iconName")}
    />
}

function AudioSlider() {
    const speaker = Wp.get_default()?.audio.defaultSpeaker!

    return <box className="AudioSlider" css="min-width: 140px">
        <icon icon={bind(speaker, "volumeIcon")} />
        <slider
            hexpand
            onDragged={({ value }) => speaker.volume = value}
            value={bind(speaker, "volume")}
        />
    </box>
}

function BatteryLevel() {
    const bat = Battery.get_default()

    return <box className="Battery"
        visible={bind(bat, "isPresent")}>
        <icon icon={bind(bat, "batteryIconName")} />
        <label label={bind(bat, "percentage").as(p =>
            `${Math.floor(p * 100)} %`
        )} />
    </box>
}

function Media() {
    const mpris = Mpris.get_default()

    return <button
        onClicked={mpris.pause}>
        <box className="Media">
        {bind(mpris, "players").as(ps => ps[0] ? (
            <box>
                <box
                    className="Cover"
                    valign={Gtk.Align.CENTER}
                    css={bind(ps[0], "coverArt").as(cover =>
                        `background-image: url('${cover}');`
                    )}
                />
                <label
                    label={bind(ps[0], "title").as(() =>
                        `${ps[0].title} - ${ps[0].artist}`
                    )}
                />
            </box>
        ) : (
            "Nothing Playing"
        ))}
    </box>
    </button>
}

function Workspaces() {
    const hypr = Hyprland.get_default()

    return <box className="Workspaces">
        {bind(hypr, "workspaces").as(wss => wss
            .sort((a, b) => a.id - b.id)
            .map(ws => (
                <button
                    className={bind(hypr, "focusedWorkspace").as(fw =>
                        ws === fw ? "focused" : "")}
                    onClicked={() => ws.focus()}>
                    {ws.id}
                </button>
            ))
        )}
    </box>
}

function FocusedClient() {
    const hypr = Hyprland.get_default()
    const focused = bind(hypr, "focusedClient")

    return <box
        className="Focused"
        visible={focused.as(Boolean)}>
        {focused.as(client => (
            client && <label label={bind(client, "title").as(String)} />
        ))}
    </box>
}


const time = Variable<string>("").poll(10000, () =>
    GLib.DateTime.new_now_local().format(" %l:%M %p")!
)

function Time({ dateFormat = " %A the %eblank of %B", dayFormat = "%e" }) {
    const nth = (d: number) => {
        if (d > 3 && d < 21) return 'th';
        switch (d % 10) {
            case 1: return "st";
            case 2: return "nd";
            case 3: return "rd";
            default: return "th";
        }
    };

    const day = Variable<number>(3).poll(60000, () =>
        parseInt(GLib.DateTime.new_now_local().format(dayFormat)!)
    )

    const date = Variable<string>("").poll(60000, () =>
        (GLib.DateTime.new_now_local().format(dateFormat)!).replace("blank", nth(day().get()))
    )

    return <label
        tooltipText={date()}
        className="Time"
        onDestroy={() => time.drop()}
        label={time()}
    />
}


const studyMode = Variable(false)
const studyPaused = Variable(true)
const studying = Variable(false)
let timeLeftStudying = 31
const studyLabel = Variable.derive(
    [studyPaused, time, studying],
    (a, b, c) => `${a ? "Study" : "Stop"} ${b} ${c ? "" : ""}`
)
let studyCycle = -1

function Study({ monitor }: { monitor: Gdk.Monitor }) {
    return <button
        visible={studyMode((a) => a)}
        className="study-button"
        onClicked={() => {
            studyPaused.set(!studyPaused.get())
        }}>
        <label
            label={studyLabel((studyLabel) => {
                if (monitor.model === "HP P240va") return `${studyPaused.get() ? ' ' : ''}${studying.get() ? '' : ' '} ${studying.get() ? timeLeftStudying : (studyCycle % 4 ? timeLeftStudying : timeLeftStudying)}m`
                timeLeftStudying -= (studyPaused.get() || !studyMode.get()) ? 0 : 1
                if (timeLeftStudying <= 0 && studyMode.get()) {
                    studying.set(!studying.get())
                    timeLeftStudying = studying.get() ? 31 : (studyCycle % 4 ? 11 : 6)
                    ++studyCycle
                    execAsync(["bash", "-c",
`notify-send -e "${studying.get() ? "Start Studying" : (studyCycle % 4 ? "Get Up" : "Start Break")}" --icon=${studying.get() ? "easy-ebook-viewer" : (studyCycle%4 ? "emoji-food-symbolic" : "applications-games-symbolic")}`]).catch((err: any) => console.error(err))
                    Player.pause()
                }
                return `${studyPaused.get() ? ' ' : ''}${studying.get() ? '' : ' '} ${studying.get() ? timeLeftStudying : (studyCycle % 4 ? timeLeftStudying : timeLeftStudying)}m`
            })}
            className="study"/>
    </button>
}

export default function Bar(monitor: Gdk.Monitor) {
    const anchor = Astal.WindowAnchor.TOP
        | Astal.WindowAnchor.LEFT
        | Astal.WindowAnchor.RIGHT

    return <window
        className="Bar"
        gdkmonitor={monitor}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        anchor={anchor}>
        <centerbox>
            <box hexpand halign={Gtk.Align.START}>
                <StartButton />
                <Workspaces />
                {/* <FocusedClient /> */}
            </box>
            <box>
                <Time />
                <Study monitor={monitor} />
            </box>
            <box hexpand halign={Gtk.Align.END} >
                <Media />
                <AudioSlider />
                <BatteryLevel />
                <Wifi />
                <SysTray />
            </box>
        </centerbox>
    </window>
}