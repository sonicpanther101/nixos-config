import { Astal, Gtk, App } from "astal/gtk3";
import { bind } from "astal";
import AstalNotifd from "gi://AstalNotifd";

const Notif = AstalNotifd.get_default();

const notifications = bind(Notif, "notifications").as(notifications => {

	return notifications.sort((a: AstalNotifd.Notification, b: AstalNotifd.Notification) => b.time - a.time).map((notification: AstalNotifd.Notification) => (

		<eventbox
		onClick={() => notification.dismiss()}>
			<box vertical className={"notification"}>
				<centerbox>
					{notification.app_icon && (<box halign={Gtk.Align.START}>
						<icon icon={notification.app_icon} />
					</box>)}
					<box vertical halign={Gtk.Align.START}>
						<label label={notification.summary} wrap className={"title"} halign={Gtk.Align.START}/>
						<label label={notification.body}  wrap className={"body"} halign={Gtk.Align.START}/>
					</box>
					{!notification.app_icon && (<box halign={Gtk.Align.END}></box>)}
					<box halign={Gtk.Align.END}>
						<label label={notification.app_name} halign={Gtk.Align.END} className={"appname"}/>
					</box>
				</centerbox>
				<box>
					{notification.actions.map((action: AstalNotifd.Action) => {
						print(action.label, action.id)
						return (
						<button
							on_Clicked={() => {
								notification.invoke(action.id);
								notification.dismiss();
							}}>
							<label label={action.label}/>
							{/* {notification.action_icons[index] ? (<icon icon={action.label}/>) : action.label} */}
						</button>
					)})}
				</box>
			</box>
		</eventbox>
	))
});

export default ({ monitor }: { monitor: number }) => (
	<window name={`notifications${monitor}`} className={"notifications-window"} widthRequest={450} anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT} hexpand={true} layer={Astal.Layer.OVERLAY} application={App}>
		<box vertical className={"notifications"}>
			{notifications}
		</box>
	</window>
);