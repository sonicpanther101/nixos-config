import { App } from "astal/gtk3"
import { monitorFile } from "astal/file";
import style from "./css/main.scss"
import Bar from "./widget/Bar"
import AppLauncher from "./widget/AppLauncher"
import Clipboard from "./widget/Clipboard";

App.start({
    css: style,
    main: () => {
      App.get_monitors().map(Bar)
      AppLauncher()
      Clipboard()
    },
})

const CSS_DIR = `${SRC}/css`;

monitorFile(CSS_DIR, () => {
  App.apply_css(`${CSS_DIR}/main.scss`, true);
});