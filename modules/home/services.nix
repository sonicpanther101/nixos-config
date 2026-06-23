{ ... } : {
  services = {

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
