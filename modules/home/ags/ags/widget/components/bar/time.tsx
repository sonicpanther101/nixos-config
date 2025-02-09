import { Variable, GLib } from "astal"

export const time = Variable<string>("").poll(10000, () =>
    GLib.DateTime.new_now_local().format(" %l:%M %p")!
)

export default function Time({ dateFormat = " %A the %eblank of %B", dayFormat = "%e" }) {
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
        (GLib.DateTime.new_now_local().format(dateFormat)!).replace("blank", nth(day().get())).replace(" ", "")
    )

    return <label
        tooltipText={date()}
        className="Time"
        onDestroy={() => time.drop()}
        label={time()}
    />
}