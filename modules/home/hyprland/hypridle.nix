{ host, lib, ... } : {
  services.hypridle = {
    enable = true;

    settings = {
      listener = [
        {
          timeout = 60;
          # on-timeout = lib.mkIf (host != "laptop-2") "hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'";

          # on-resume = lib.mkIf (host != "laptop-2") "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
        }
      ] ++ lib.optionals (host != "desktop") [
        {
          timeout = 600;
          on-timeout = "systemctl --user start hyprlock.service";
        }
        {
          timeout = 1800;
          on-timeout = "my-sleep";
        }
      ];
    };
  };
}
