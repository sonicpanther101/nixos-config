{ username, host, ... } : {
  services.syncthing = {
    enable = true;
    # Force Syncthing to listen on a port likely to be open
    guiAddress = "127.0.0.1:8384"; 
    settings = {

      options = {
        listenAddresses = [ "tcp://0.0.0.0:8443" ]; # Needs sudo/cap_net_bind_service if using < 1024
        relaysEnabled = false;
        globalAnnounceEnabled = false;
        localAnnounceEnabled = true;
      };

      devices = {
        "Phone" = { 
          id = "U3WDNWK-4BIUXM4-OS5SUHL-EZEFTWT-22NIYE6-QEZ6YS5-5WNR7QW-DYRUKAH";
          # If your phone has a static IP on the uni wifi, put it here:
          # addresses = [ "tcp://10.x.x.x:22000" ]; 
        };
        "laptop" = { id = "K4TFO23-BFIJIKI-YCZVGVJ-HLHAEY7-6QJ2WHP-3QN6WJ3-DX74NUX-JNIVLAP"; };
        "desktop" = { id = "7LMWSE7-SIOJROW-CSVA53V-RM77RLA-GBU2T6H-GL6SYLW-UC32RBB-M3455QQ"; };
      };
      
      folders = let 
        sharedDevices = [ "Phone" ] ++ (if host == "desktop" then [ "laptop" ] else [ "desktop" ]);
        basePath = if host == "desktop" then "/home/${username}/driveBig" else "/home/${username}";
      in {
        "School" = { id = "r7hv7-6lau7"; path = "${basePath}/School/"; devices = sharedDevices; };
        "Guitar" = { id = "zevcu-jzwwx"; path = "${basePath}/Guitar/"; devices = sharedDevices; };
        "Music"  = { id = "csoaz-zgdyy"; path = "${basePath}/Music/";  devices = sharedDevices; };
        "Research Papers" = { id = "p2539-fht3j"; path = "${basePath}/Research Papers/"; devices = sharedDevices; };
      };
    };
  };
}