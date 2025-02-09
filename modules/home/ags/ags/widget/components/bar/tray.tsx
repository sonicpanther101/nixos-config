import AstalTray from "gi://AstalTray";
import { bind, Gio } from "astal"
import { Gtk, Gdk, Widget } from "astal/gtk3"

const tray = AstalTray.get_default();

type TrayItem = ReturnType<ReturnType<typeof AstalTray.Tray.get_default>["get_item"]>;

function createMenu(menuModel: Gio.MenuModel, actionGroup: Gio.ActionGroup): Gtk.Menu {
	const menu: Gtk.Menu = Gtk.Menu.new_from_model(menuModel);
	menu.insert_action_group("dbusmenu", actionGroup);
	return menu;
}

const TrayItem = (item: TrayItem) => {
  // const menu = item.create_menu();
  const menu: Gtk.Menu = createMenu(item.menu_model, item.action_group);

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
    <button className="TrayItem" onClick={onClick}>
      <icon
        icon={bind(item, "iconName").as((name) => name ?? "")}
        pixbuf={bind(item, "iconPixbuf")}
      />
    </button>
  );
};

export default function SysTray() {
  let itemAddedId: number | null = null;
  let itemRemovedId: number | null = null;

  const setup = (self: Widget.Box) => {
    self.children = tray.get_items().map((item: AstalTray.TrayItem) => TrayItem(item));

    itemAddedId = tray.connect("item-added", (_: any, itemId: string) =>
      self.add(TrayItem(tray.get_item(itemId))),
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
        orientation={Gtk.Orientation.HORIZONTAL}
        spacing={8}
        setup={setup}
        onDestroy={onDestroy}
    />
  );
};