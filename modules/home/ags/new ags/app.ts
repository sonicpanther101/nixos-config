import { App } from "astal/gtk3"
import monitorStyle from "./cssHotLoad";
import style from "./css/main.scss"
import Bar from "./widget/Bar"
import AppLauncher from "./widget/AppLauncher"
import Clipboard from "./widget/Clipboard";
import Notifications from "./widget/Notifications";
import APIs from "./widget/Apis";
import Wallaper from "./widget/Wallaper";

monitorStyle;

App.start({
    css: style,
    main: () => {
      App.get_monitors().map(Bar);
      AppLauncher();
      Clipboard();
      Notifications({ monitor: 0 });
      APIs();
      Wallaper();
    },
})