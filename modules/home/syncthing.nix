{ username, host, config, ... } : {
  services.syncthing = {
    enable = true;
    # Force Syncthing to listen on a port likely to be open
    guiAddress = "127.0.0.1:8384"; 
    settings = {

      # options = {
      #   listenAddresses = [ "tcp://0.0.0.0:8443" ]; # Needs sudo/cap_net_bind_service if using < 1024
      #   relaysEnabled = false;
      #   globalAnnounceEnabled = false;
      #   localAnnounceEnabled = true;
      # };

      devices = {
        "Phone" = { id = "U3WDNWK-4BIUXM4-OS5SUHL-EZEFTWT-22NIYE6-QEZ6YS5-5WNR7QW-DYRUKAH"; };
        "laptop" = { id = "K4TFO23-BFIJIKI-YCZVGVJ-HLHAEY7-6QJ2WHP-3QN6WJ3-DX74NUX-JNIVLAP"; };
        "laptop-2" = { id = "HHDHHNC-TBXSLRH-3ZMQ5WW-VVKJ42V-GVRJG76-VNSVHO3-INIDR5X-OWHGIAX"; };
        "desktop" = { id = "7LMWSE7-SIOJROW-CSVA53V-RM77RLA-GBU2T6H-GL6SYLW-UC32RBB-M3455QQ"; };
      };
      
      folders = let
        deviceNames = builtins.attrNames config.services.syncthing.settings.devices;
        sharedDevices = builtins.filter (d: d != host) deviceNames;

        basePath = if host == "desktop"
          then "/home/${username}/driveBig"
          else "/home/${username}";
      in {
        "Kobo" = {
          id = "m7cg8-2a7jo";
          path = "${basePath}/Kobo/";
          devices = sharedDevices;
        };

        "Guitar" = {
          id = "zevcu-jzwwx";
          path = "${basePath}/Guitar/";
          devices = sharedDevices;
        };

        "Music" = {
          id = "csoaz-zgdyy";
          path = "${basePath}/Music/";
          devices = sharedDevices;
        };

        "Research Papers" = {
          id = "p2539-fht3j";
          path = "${basePath}/Research Papers/";
          devices = sharedDevices;
        };

        "Uni Notes" = {
          id = "aenix-pe2ge";
          path = "${basePath}/Uni Notes/";
          devices = sharedDevices;
        };
      };
    };
  };
}