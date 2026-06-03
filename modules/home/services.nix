{ ... } : {
  services = {
    
    # Temporary notifications daemon to shut grimblast up
    mako = {
      enable = true;
      
      settings.default-timeout = 5000; # 5 seconds default for all notifications
      
      # Set NetworkManager Applet notifications to timeout after 3 seconds
      extraConfig = ''
        [app-name="NetworkManager Applet"]
        default-timeout=3000
      '';
    };
      
    # Screen shader
    hyprsunset = {
      enable = true;

      settings = {
        profile = [{
          time = "7:30";
          identity = true;
        }

        {
          time = "21:00";
          temperature = 5500;
          gamma = 0.8;
        }];
      };
    };
    
    # For walker
    elephant.enable = true;
  };
}