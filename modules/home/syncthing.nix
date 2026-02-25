{ username, host, ... } : {
  services.syncthing = {
    enable = true;
    guiAddress = "100.110.147.68:8384";
    settings = {

      overrideDevices = true;
      overrideFolders = true;

      options = {
        # Tell Syncthing to listen on all interfaces at port 22000
        listenAddresses = [ 
          "default"
          "tcp://0.0.0.0:22000"
        ];

        globalAnnounceEnabled = false;
        localAnnounceEnabled = false;
      };

      devices = {
        "Phone" = { id = "U3WDNWK-4BIUXM4-OS5SUHL-EZEFTWT-22NIYE6-QEZ6YS5-5WNR7QW-DYRUKAH"; };
      } // (if (host == "desktop") then {
          "laptop" = { id = "K4TFO23-BFIJIKI-YCZVGVJ-HLHAEY7-6QJ2WHP-3QN6WJ3-DX74NUX-JNIVLAP"; };
        } else {
          "desktop" = { id = "7LMWSE7-SIOJROW-CSVA53V-RM77RLA-GBU2T6H-GL6SYLW-UC32RBB-M3455QQ"; };
        });
      folders = {
        "School" = {
          id = "r7hv7-6lau7";
          path = if (host == "desktop") then "/home/${username}/driveBig/School/" else "/home/${username}/School/";
          devices = [ "Phone" ] ++ (if (host == "desktop") then [ "laptop" ] else [ "desktop" ]);
        };
        "Guitar" = {
          id = "zevcu-jzwwx";
          path = if (host == "desktop") then "/home/${username}/driveBig/Guitar/" else "/home/${username}/Guitar/";
          devices = [ "Phone" ] ++ (if (host == "desktop") then [ "laptop" ] else [ "desktop" ]);
        };
        "Music" = {
          id = "csoaz-zgdyy";
          path = if (host == "desktop") then "/home/${username}/driveBig/Music/" else "/home/${username}/Music/";
          devices = [ "Phone" ] ++ (if (host == "desktop") then [ "laptop" ] else [ "desktop" ]);
        };
        "Research Papers" = {
          id = "p2539-fht3j";
          path = if (host == "desktop") then "/home/${username}/driveBig/Research Papers/" else "/home/${username}/Research Papers/";
          devices = [ "Phone" ] ++ (if (host == "desktop") then [ "laptop" ] else [ "desktop" ]);
        };
      };
    };
  };
}