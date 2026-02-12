{ host, pkgs-unstable, pkgs-stable, lib, username, ... } : {

  # port 8384 is the default port to allow syncthing GUI access from the network.
  networking.firewall.allowedTCPPorts = [ 8384 ];
  
  services = {

    # Bluetooth UI
    blueman.enable = true;

    # Getting sleep to work
    logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandlePowerKey = if (host == "desktop") then "
        suspend-then-hibernate
      " else "
        ignore
      ";
      HandlePowerKeyLongPress = "poweroff";
    };

    # Configure keymap in X11
    xserver.xkb = {
      layout = "nz";
      variant = "";
    };

    # for bambu studio: flatpak run com.bambulab.BambuStudio
    flatpak = {
      enable = true;
    };

    # Syncthing
    syncthing = {
      openDefaultPorts = true; # Open ports in the firewall for Syncthing. (NOTE: this will not open syncthing gui port)
    };

    # NextDNS service with DoH
    nextdns = {
      enable = true;
      arguments = [
        "-config" "176a88"           # Your NextDNS config ID
        # "-cache-size" "10MB"         # Optional: local cache
        # "-use-hosts" "true"          # Optional: use /etc/hosts
      ];
    };

    # Auto login for hyprland startup
    displayManager.autoLogin = {
      enable = true;
      user = "${username}";
    };
  
    # Add getty configuration for auto-login
    getty.autologinUser = "${username}";
  } // (if (host == "laptop") then {

    upower = {
      enable = true;
      percentageLow = 20;
      percentageCritical = 5;
      percentageAction = 3;
      criticalPowerAction = "PowerOff";
    };

    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "performance";
          turbo = "auto";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };
  } else if (host == "desktop") then {
    # nvidia
    xserver.videoDrivers = ["nvidia"];  

    # Stop keypresses and mouse movement turning on from sleep.
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="1532", ATTRS{idProduct}=="00c5", ATTR{power/wakeup}="disabled"
      ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0361", ATTR{power/wakeup}="disabled"
      SUBSYSTEMS=="usb|hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0361", TAG+="uaccess", TAG+="Keychron V6"
      
      # Disable network adapter wake-on-LAN/WiFi to prevent immediate wake from suspend
      ACTION=="add", SUBSYSTEM=="net", KERNEL=="eth*|enp*", RUN+="${pkgs-stable.ethtool}/bin/ethtool -s $name wol d"
      ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", ATTR{device/power/wakeup}="disabled"
    '';

    # OpenRGB
    udev.packages = [ pkgs-unstable.openrgb ];
  } else {});
  boot.kernelModules = if (host == "desktop") then [ "i2c-dev" "i2c-piix4" ] else []; # "nouveau" ];
  users.groups.i2c.members = [ username ];
}