import { Astal, Gdk, App, Widget } from "astal/gtk3";
import { timeout, Variable } from "astal";
import AstalNotifd from "gi://AstalNotifd";
import NotifWidget from "./components/notifications/notification";

const Notif = AstalNotifd.get_default();
const waitTime = new Variable(2000);
const expireTime = new Variable(20000);

export default ({ monitor }: { monitor: number }) => (
	<window name={`notifications${monitor}`} widthRequest={450} anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT} hexpand={true} layer={Astal.Layer.OVERLAY} application={App}>
		{/* <NotifItem /> */}
	</window>
);