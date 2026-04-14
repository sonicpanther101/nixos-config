{ host, ... } : {
  services.hypridle = {
    enable = true;

    settings = {
      listener = [
        {
          timeout = 60;
          on-timeout = "hyprctl dispatch dpms off";

          on-resume = "hyprctl dispatch dpms on";
        }
      ] ++ (if (host != "desktop") then [
        {
          timeout = 600;
          on-timeout = "pidof swaylock || swaylock --daemonize";
        }
        {
          timeout = 1800;
          on-timeout = "my-sleep";
        }
      ] else []);
    };
  };
}