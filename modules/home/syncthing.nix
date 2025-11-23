{ username, host, ... } : {
  services.syncthing = {
    enable = true;
    settings = {
      devices = {
        "Phone" = { id = "U3WDNWK-4BIUXM4-OS5SUHL-EZEFTWT-22NIYE6-QEZ6YS5-5WNR7QW-DYRUKAH"; };
      } // (if (host == "desktop") then {
          "laptop" = { id = "7LMWSE7-SIOJROW-CSVA53V-RM77RLA-GBU2T6H-GL6SYLW-UC32RBB-M3455QQ"; };
        } else {
          "desktop" = { id = "7LMWSE7-SIOJROW-CSVA53V-RM77RLA-GBU2T6H-GL6SYLW-UC32RBB-M3455QQ"; };
        });
      folders = {
        "School" = {
          id = "r7hv7-6lau7";
          path = if (host == "desktop") then "/home/${username}/driveBig/School/" else "/home/${username}/School/";
          devices = [ "Phone" ] ++ (if (host == "desktop") then [ "laptop" ] else [ "desktop" ]);
        };
      };
    };
  };
}