import Mpris from "gi://AstalMpris"
import { Variable, bind, execAsync, Binding } from "astal"
import { Astal, Gdk, Widget } from "astal/gtk3"
import { time } from "./time"


export const studyMode = Variable(false)
export const studyPaused = Variable(true)
export const studying = Variable(false)
export const timeLeftStudying = Variable(31)
const studyLabel = Variable.derive(
    [studyPaused, time, studying],
    (a, b, c) => `${a ? "Study" : "Stop"} ${b} ${c ? "" : ""}`
)
let studyCycle = 0

export default function Study({ monitor }: { monitor: Gdk.Monitor }) {

    const mpris = Mpris.get_default()

    const onClick: Widget.ButtonProps["onClick"] = (_, e: Astal.ClickEvent) => {
        if (e.button === Gdk.BUTTON_PRIMARY) {
            timeLeftStudying.set(studying.get() ? (studyCycle % 4 ? 11 : 6) : 31)
            ++studyCycle
            studying.set(!studying.get())
        } else if (e.button === Gdk.BUTTON_SECONDARY) {
            studyPaused.set(!studyPaused.get())
            timeLeftStudying.set(timeLeftStudying.get() + (studyPaused.get() ? 1 : 0))
        }
    };

    const player: Binding<Mpris.Player> = bind(mpris, "players").as(ps => ps[0])

    return <button
        visible={studyMode((a) => a)}
        className="Study"
        onClick={onClick}>
        <label
            label={studyLabel((studyLabel) => {
                if (monitor.model === "HP P240va") return `${studyPaused.get() ? ' ' : ''}${studying.get() ? '' : ' '} ${studying.get() ? timeLeftStudying.get() : (studyCycle % 4 ? timeLeftStudying.get() : timeLeftStudying.get())}m`
                timeLeftStudying.set(timeLeftStudying.get() - ((studyPaused.get() || !studyMode.get()) ? 0 : 1))
                if (timeLeftStudying.get() <= 0 && studyMode.get()) {
                    studying.set(!studying.get())
                    timeLeftStudying.set(studying.get() ? 31 : (studyCycle % 4 ? 11 : 6))
                    ++studyCycle
                    execAsync(["bash", "-c", `notify-send -e "${studying.get() ? "Start Studying" : (studyCycle % 4 ? "Get Up" : "Start Break")}" --icon=${studying.get() ? "easy-ebook-viewer" : (studyCycle%4 ? "emoji-food-symbolic" : "applications-games-symbolic")}`]).catch((err: any) => console.error(err))
                    player.get().play_pause()
                }
                return `${studyPaused.get() ? ' ' : ''}${studying.get() ? '' : ' '} ${studying.get() ? timeLeftStudying.get() : (studyCycle % 4 ? timeLeftStudying.get() : timeLeftStudying.get())}m`
            })}
            className="study"/>
    </button>
}