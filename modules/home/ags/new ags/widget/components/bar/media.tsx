import Mpris from "gi://AstalMpris"
import Player from "gi://AstalMpris"
import { Variable, bind } from "astal"
import { Astal, Gtk, Gdk, Widget } from "astal/gtk3"

export default function Media() {
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
            <slider>
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
            </slider>
            </button>
        ) : (
            ""
        ))}
    </box>
}