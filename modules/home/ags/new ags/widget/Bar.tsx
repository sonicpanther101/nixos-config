import { Astal, Gtk, Gdk } from "astal/gtk3"

import StartButton from "./components/bar/start"
import Workspaces from "./components/bar/workspaces"
import FocusedClient from "./components/bar/focused"
import Time from "./components/bar/time"
import Study from "./components/bar/study"
import Media from "./components/bar/media"
import Audio from "./components/bar/audio"
import BatteryLevel from "./components/bar/battery"
import SysTray from "./components/bar/tray"

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
                <Workspaces monitor={monitor} />
                {/* <FocusedClient /> */}
            </box>
            <box>
                <Time />
                <Study monitor={monitor} />
            </box>
            <box hexpand halign={Gtk.Align.END} className="Right">
                <Media />
                <Audio />
                <BatteryLevel />
                <SysTray />
            </box>
        </centerbox>
    </window>
}