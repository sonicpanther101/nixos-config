import { App } from "astal/gtk3"
import { Variable, GLib, bind, execAsync, Binding } from "astal"
import { Astal, Gtk, Gdk, Widget } from "astal/gtk3"
import Hyprland from "gi://AstalHyprland"
import Mpris from "gi://AstalMpris"
import Player from "gi://AstalMpris"
import Battery from "gi://AstalBattery"
import Wp from "gi://AstalWp"
import Network from "gi://AstalNetwork"
import AstalTray from "gi://AstalTray";

function StartButton() {
    return <button
        className="StartButton"
        onClicked={() => {
            studyMode.set(!studyMode.get())
            if (studyMode.get()) {
                studyPaused.set(false)
                timeLeftStudying = 31
                studying.set(true)
            }
        }}>
        <label label=" " />
    </button>
}


const tray = AstalTray.get_default();

const TrayItem = (id: string, item: AstalTray.TrayItem) => {
  const menu = item.create_menu();

  const onClick: Widget.ButtonProps["onClick"] = (_, e) => {
    if (e.button === Gdk.BUTTON_PRIMARY) {
      item.activate(Gdk.Screen.width() / 2, Gdk.Screen.height() / 2);
    } else if (e.button === Gdk.BUTTON_SECONDARY) {
      menu?.popup_at_pointer(null);
    } else if (e.button === Gdk.BUTTON_MIDDLE) {
      item.secondary_activate(Gdk.Screen.width() / 2, Gdk.Screen.height() / 2);
    }
  };

  return (
    <button name={id} className="TrayItem" onClick={onClick}>
      <icon
        icon={bind(item, "iconName").as((name) => name ?? "")}
        pixbuf={bind(item, "iconPixbuf")}
      />
    </button>
  );
};

const SysTray = () => {
  let itemAddedId: number | null = null;
  let itemRemovedId: number | null = null;

  const setup = (self: Widget.Box) => {
    self.children = tray.get_items().map((item: AstalTray.TrayItem) => TrayItem(item.itemId, item));

    itemAddedId = tray.connect("item-added", (_: any, itemId: string) =>
      self.add(TrayItem(itemId, tray.get_item(itemId))),
    );
    itemRemovedId = tray.connect("item-removed", (_: any, itemId: string) => {
      const widget = self.children.find((w) => w.name === itemId);
      widget?.destroy();
    });
  };

  const onDestroy = () => {
    if (itemAddedId) {
      tray.disconnect(itemAddedId);
    }
    if (itemRemovedId) {
      tray.disconnect(itemRemovedId);
    }
  };

  return (
      <box
        className="SysTray"
        orientation={Gtk.Orientation.VERTICAL}
        spacing={8}
        setup={setup}
        onDestroy={onDestroy}
    />
  );
};

function Audio() {
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

    const onScroll: (_: Widget.Button, e: Astal.ScrollEvent, player: Player) => void = (_, e, player) => {
        let direction: -1 | 1 | null = null;
        if (e.direction == Gdk.ScrollDirection.SMOOTH) {
            direction = Math.sign(e.delta_y) as 1 | -1;
        } else if (e.direction == Gdk.ScrollDirection.UP) {
            direction = 1;
        } else if (e.direction == Gdk.ScrollDirection.DOWN) {
            direction = -1;
        }
        if (direction === 1) {
            player.previous()
        } else if (direction === -1) {
            player.next()
        }
    };

    return <box>
        {bind(mpris, "players").as(ps => ps[0] ? (
            <button
            onClicked={()=>ps[0].play_pause()}
            onScroll={(_, e) => onScroll(_, e, ps[0])}
            className="Media"
            visible={bind(ps[0], "title").as(Boolean)}
            css={bind(Variable.derive(
                [bind(ps[0], "position").as(Number), bind(ps[0], "length").as(Number)],
                (p, l) => {
                    if (l === 0 || p === 0 || p / l === Infinity) {
                        return ""
                    } else {
                        return `background: linear-gradient(90deg, rgba(0,0,0,0.7) ${100 * p / l}%, rgba(0,0,0,0) ${(100 * p / l) + 10}%);`
                    }
                }
            ))}>
            <box
            tooltipText={bind(ps[0], "album").as(String)}>
                <label
                    label={bind(Variable.derive(
                        [bind(ps[0], "title").as(String), bind(ps[0], "artist").as(String), bind(ps[0], "playbackStatus").as(Boolean)],
                        (t, a, p) => {
                            return `${p ? " " : " "}${t}${a ? " - " : ""}${a}`
                        }
                    ))}
                    truncate
                />
                <box
                    className="Cover"
                    valign={Gtk.Align.CENTER}
                    css={bind(ps[0], "coverArt").as(cover => `background-image: url('${cover}');`)}
                />
            </box>
            </button>
        ) : (
            ""
        ))}
    </box>
}

function Workspaces({ monitor }: { monitor: Gdk.Monitor }) {
    const hyprland = Hyprland.get_default()

    const currentWorkspace = () => hyprland.get_focused_workspace().get_id();
    
    return <box className="Workspaces">
        {Array.from({ length: 10 }, (_, i) => i + (monitor.model === "HP P232" ? 1 : 11)).map(id => (
            <button
                setup={(self)=> {self.hook(hyprland, "event",(self) => {
                    self.toggleClassName("active", id === currentWorkspace())
                    self.toggleClassName("occupied", hyprland.get_workspace(id)?.get_clients().length > 0)
                })}} 
                onClicked={() => hyprland.get_focused_workspace().get_id() != id ? hyprland.dispatch("workspace", `${id}`) : null}
                halign={Gtk.Align.CENTER}>
                <label
                    label={bind(hyprland, "focusedWorkspace").as(fw => fw && fw.id === id ? "●" : `${id}`)}
                />
            </button>
        ))}
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
let studyCycle = 0

function Study({ monitor }: { monitor: Gdk.Monitor }) {

    const mpris = Mpris.get_default()

    const onClick: Widget.ButtonProps["onClick"] = (_, e: Astal.ClickEvent) => {
        if (e.button === Gdk.BUTTON_PRIMARY) {
            timeLeftStudying = studying.get() ? (studyCycle % 4 ? 11 : 6) : 31
            ++studyCycle
            studying.set(!studying.get())
        } else if (e.button === Gdk.BUTTON_SECONDARY) {
            studyPaused.set(!studyPaused.get())
            timeLeftStudying += studyPaused.get() ? 1 : 0
        }
    };

    const player: Binding<Player> = bind(mpris, "players").as(ps => ps[0])

    return <button
        visible={studyMode((a) => a)}
        className="Study"
        onClick={onClick}>
        <label
            label={studyLabel((studyLabel) => {
                if (monitor.model === "HP P240va") return `${studyPaused.get() ? ' ' : ''}${studying.get() ? '' : ' '} ${studying.get() ? timeLeftStudying : (studyCycle % 4 ? timeLeftStudying : timeLeftStudying)}m`
                timeLeftStudying -= (studyPaused.get() || !studyMode.get()) ? 0 : 1
                if (timeLeftStudying <= 0 && studyMode.get()) {
                    studying.set(!studying.get())
                    timeLeftStudying = studying.get() ? 31 : (studyCycle % 4 ? 11 : 6)
                    ++studyCycle
                    execAsync(["bash", "-c", `notify-send -e "${studying.get() ? "Start Studying" : (studyCycle % 4 ? "Get Up" : "Start Break")}" --icon=${studying.get() ? "easy-ebook-viewer" : (studyCycle%4 ? "emoji-food-symbolic" : "applications-games-symbolic")}`]).catch((err: any) => console.error(err))
                    player.get().play_pause()
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