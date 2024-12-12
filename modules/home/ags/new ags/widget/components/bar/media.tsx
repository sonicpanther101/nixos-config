import Mpris from "gi://AstalMpris"
import { Variable, bind } from "astal"
import { Astal, Gtk, Gdk, Widget } from "astal/gtk3"

export default function Media() {
  const mpris = Mpris.get_default()

  const onClick: (_: Widget.Button, e: Astal.ClickEvent, player: Mpris.Player) => void = (_, e, player) => {
    if (e.button === Gdk.BUTTON_PRIMARY) {
      player.play_pause()
    } else if (e.button === Gdk.BUTTON_SECONDARY) {
      print(player.get_can_raise())
      player.get_can_raise() && player.raise()
    }
  };

  const onScroll: (_: Widget.Button, e: Astal.ScrollEvent, player: Mpris.Player) => void = (_, e, player) => {
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

  return (<box>
    {bind(mpris, "players").as(ps => ps[0] && (
        <button
          onClick={(_, e) => onClick(_, e, ps[0])}
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
                  return `${p ? "" : ""} ${t}${a ? " - " : ""}${a}`
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
      )
    )}
  </box>)
}