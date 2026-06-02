{ host, lib, ... } : {
  services.hypridle = {
    enable = true;

    settings = {
      listener = [
        {
          timeout = 60;
          on-timeout = lib.mkIf (host != "laptop-2") "hyprctl dispatch dpms off";

          on-resume = lib.mkIf (host != "laptop-2") "hyprctl dispatch dpms on";
        }
      ] ++ lib.optionals (host != "desktop") [
        {
          timeout = 600;
          on-timeout = "pidof hyprlock || hyprlock";
        }
        {
          timeout = 1800;
          on-timeout = "my-sleep";
        }
      ];
    };
  };
}