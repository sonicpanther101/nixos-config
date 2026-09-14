{ ... } : {
  services = {

    # Auto-mounts USB drives on plug-in (e.g. the Ventoy drive used by
    # my-backup.sh) to /run/media/$USER/<LABEL>, with a tray icon and
    # unmount notifications.
    udiskie = {
      enable = true;
      tray = "auto";
      automount = true;
      notify = true;
    };

    # Notification Manager
    swaync = {
      enable = true;
      settings = {
        timeout = 5;
        notification-window-width = 300;
      };
    };
      
    # Screen shader
    hyprsunset = {
      enable = true;

      settings = {
        profile = [{
          time = "9:30";
          identity = true;
        }

        {
          time = "21:00";
          temperature = 5500;
          gamma = 0.8;
        }];
      };
    };
  };
}
