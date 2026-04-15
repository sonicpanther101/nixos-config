{ host, ... } : {
  services.hypridle = {
    enable = true;

    settings = {
      listener = [
        {
          timeout = 60;
          on-timeout = (if (host != "laptop-2") then "hyprctl dispatch dpms off" else "");

          on-resume = (if (host != "laptop-2") then "hyprctl dispatch dpms on" else "");
        }
      ] ++ (if (host != "desktop") then [
        {
          timeout = 600;
          on-timeout = "pidof swaylock || swaylock";
        }
        {
          timeout = 1800;
          on-timeout = "my-sleep";
        }
      ] else []);
    };
  };
}