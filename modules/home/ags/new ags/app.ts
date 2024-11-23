import { App } from "astal/gtk3"
import { monitorFile } from "astal/file";
import style from "./css/main.scss"
import { toggleWindow } from "./lib/utils"
import Bar from "./widget/Bar"
import AppLauncher from "./widget/AppLauncher"

App.start({
    css: style,
    instanceName: "js",
    requestHandler(request: string, res: (response: any) => void) {
        const args = request.split(" ");
        if (args[0] == "toggle") {
            toggleWindow(args[1]);
            res("ok");
        }
    },
    main: () => {
        App.get_monitors().map(Bar)
        AppLauncher()
    },
})

const CSS_DIR = `${SRC}/css`;

monitorFile(CSS_DIR, () => {
  App.apply_css(`${CSS_DIR}/main.scss`, true);
});