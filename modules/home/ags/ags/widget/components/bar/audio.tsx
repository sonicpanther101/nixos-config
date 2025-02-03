import Wp from "gi://AstalWp"
import { bind, execAsync } from "astal"
import { Astal, Gdk, Widget } from "astal/gtk3"

export default function Audio() {
    const speaker = Wp.get_default()?.audio.defaultSpeaker!

    const onClick: Widget.ButtonProps["onClick"] = (_, e: Astal.ClickEvent) => {
        if (e.button === Gdk.BUTTON_PRIMARY) {
            speaker.set_mute(!speaker.mute)
        } else if (e.button === Gdk.BUTTON_SECONDARY) {
            execAsync(["pavucontrol"]).catch((err: any) => console.error(err))
        }
    };

    const onScroll: Widget.ButtonProps["onScroll"] = (_, e: Astal.ScrollEvent) => {
        let direction: -1 | 1 | null = null;
        if (e.direction == Gdk.ScrollDirection.SMOOTH) {
            direction = Math.sign(e.delta_y) as 1 | -1;
        } else if (e.direction == Gdk.ScrollDirection.UP) {
            direction = 1;
        } else if (e.direction == Gdk.ScrollDirection.DOWN) {
            direction = -1;
        }
        if (direction === null) return
        speaker.set_volume(Math.min(1, Math.max(0, Math.round(speaker.get_volume() * 20) / 20 - direction * 0.05)));
    };

    return <button className="Audio"
        onClick={onClick} onScroll={onScroll}>
        <box>
            <icon icon={bind(speaker, "volumeIcon")} />
            <label label={bind(speaker, "volume").as(p => ` ${Math.round(p * 20) * 5}%`)} />
        </box>
    </button>
}