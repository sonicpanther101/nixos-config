import Hyprland from "gi://AstalHyprland"
import { bind } from "astal"
import { Gtk, Gdk } from "astal/gtk3"

export default function Workspaces({ monitor }: { monitor: Gdk.Monitor }) {
    const hyprland = Hyprland.get_default()

    const currentWorkspace = () => hyprland.get_focused_workspace().get_id();
    
    return <box className="Workspaces">
        {Array.from({ length: 10 }, (_, i) => i + (monitor.model === "27B30H" ? 11 : 1)).map(id => ( // TODO: get other monitor name
            <button
                setup={(self)=> {self.hook(hyprland, "event",(self) => {
                    self.toggleClassName("active", id === currentWorkspace())
                    self.toggleClassName("occupied", hyprland.get_workspace(id)?.get_clients().length > 0)
                })}} 
                onClicked={() => hyprland.get_focused_workspace().get_id() != id ? hyprland.dispatch("workspace", `${id}`) : null}
                halign={Gtk.Align.CENTER}>
                <label
                    label={bind(hyprland, "focusedWorkspace").as(fw => fw && fw.id === id ? "●" : `${id > 10 ? id - 10 : id}`)}
                />
            </button>
        ))}
    </box>
}