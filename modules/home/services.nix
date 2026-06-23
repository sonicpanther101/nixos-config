{ ... } : {
  services = {

    # Notification Manager
    swaync = {
      enable = true;
      settings = {
        timeout = 5;
      };
      style = ''
        .notification-row {
          min-height: 0px;
        }

        .notification {
          min-width: 0px;
          min-height: 0px;
          padding: 8px;
        }
      '';
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
