{ username, host, isServer, config, lib, ... } : {
  services.syncthing = {
    enable = true;
    # Force Syncthing to listen on a port likely to be open
    guiAddress = "127.0.0.1:8384"; 
    settings = {

      devices = {
        "Phone" = { id = "U3WDNWK-4BIUXM4-OS5SUHL-EZEFTWT-22NIYE6-QEZ6YS5-5WNR7QW-DYRUKAH"; };
        "laptop-1" = { id = "K4TFO23-BFIJIKI-YCZVGVJ-HLHAEY7-6QJ2WHP-3QN6WJ3-DX74NUX-JNIVLAP"; };
        "laptop-2" = { id = "HHDHHNC-TBXSLRH-3ZMQ5WW-VVKJ42V-GVRJG76-VNSVHO3-INIDR5X-OWHGIAX"; };
        "desktop" = { id = "7LMWSE7-SIOJROW-CSVA53V-RM77RLA-GBU2T6H-GL6SYLW-UC32RBB-M3455QQ"; };
        "server" = { id = "RHARASO-HG4S4CR-QQ5WHUZ-HEOTLBE-GIGFCOL-B52R2NK-6HY6VAF-C4PGRQO"; };
      };
      
      folders = let
        deviceNames = builtins.attrNames config.services.syncthing.settings.devices;
        sharedDevices = builtins.filter (d: d != host) deviceNames;

        basePath = if host == "desktop" || host == "laptop-1" || isServer then
          "/home/${username}/driveBig"
        else
          "/home/${username}";
      in {
        "Books" = {
          id = "m7cg8-2a7jo";
          path = "${basePath}/Books/";
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
          # On the server Lidarr also writes into this library, so don't let the
          # other devices' 0755 folders overwrite the group-writable ones here
          ignorePerms = isServer;
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
  # Server only: files and folders Syncthing creates come out group-writable, so
  # Lidarr (group `users`) can add albums to artist folders that arrived by sync
  systemd.user.services.syncthing.Service.UMask = lib.mkIf isServer "0002";
}
