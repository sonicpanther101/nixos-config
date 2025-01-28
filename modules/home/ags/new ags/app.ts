import { App } from "astal/gtk3"
import { monitorFile } from "astal"
import style from "./css/main.scss"
import Bar from "./widget/Bar"
import AppLauncher from "./widget/AppLauncher"
import Clipboard from "./widget/Clipboard";
import Notifications from "./widget/Notifications";
import APIs from "./widget/Apis";
import Wallaper from "./widget/Wallaper";
import Dashboard from "./widget/Dashboard"

App.start({
    css: style,
    main: () => {
      App.get_monitors().map(Bar);
      AppLauncher();
      Clipboard();
      Notifications({ monitor: 0 });
      APIs();
      Wallaper();
      Dashboard();
    },
})

const CSS_DIR = `${SRC}/css`;

monitorFile(CSS_DIR, () => {
  App.apply_css(`${CSS_DIR}/main.scss`, true);
});