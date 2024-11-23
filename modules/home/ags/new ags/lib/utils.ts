import { App } from "astal/gtk3";

export function toggleWindow(windowName: string) {
	const window = App.get_window(windowName);
	if (!window) return;

	window.visible = window.visible ? false : true;
}