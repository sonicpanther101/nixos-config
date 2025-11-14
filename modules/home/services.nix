{ ... } : {
  services.syncthing = {
    enable = true;
    settings = {
      devices = {
        "Phone" = { id = "U3WDNWK-4BIUXM4-OS5SUHL-EZEFTWT-22NIYE6-QEZ6YS5-5WNR7QW-DYRUKAH"; };
      };
      folders = {
        "School" = {
          id = "r7hv7-6lau7";
          path = "/home/adam/driveBig/School/";
          devices = [ "Phone" ];
        };
      };
    };
  };
}