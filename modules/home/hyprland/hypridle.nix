{ host, ... } : {
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        # lock_cmd = "swaylock";

        # before_sleep_cmd = "swaylock";
        # after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 60;
          on-timeout = "hyprctl dispatch dpms off";

          on-resume = "hyprctl dispatch dpms on";
        }
      ] ++ (if (host == "laptop") then [
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