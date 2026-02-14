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
    # for cura: flatpak run com.ultimaker.cura
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
    # CRITICAL FIXES:
    # 1. Use DRIVER=="usb" instead of DRIVERS=="usb" - matches only actual USB devices, not interfaces
    # 2. This prevents the ":1.0", ":1.1" interface errors you were seeing
    udev.extraRules = ''
      # Razer mouse (1532:00c5) - disable wake
      ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTRS{idVendor}=="1532", ATTRS{idProduct}=="00c5", ATTR{power/wakeup}="disabled"
      
      # Keychron V6 keyboard (3434:0361) - disable wake
      ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0361", ATTR{power/wakeup}="disabled"
      
      # Disable ALL USB device wake by default (more aggressive approach)
      # Comment this out if it causes issues, but it may be needed
      ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{power/wakeup}="disabled"
      
      # Disable network adapter wake-on-LAN/WiFi
      ACTION=="add", SUBSYSTEM=="net", KERNEL=="eth*|enp*", RUN+="${pkgs-stable.ethtool}/bin/ethtool -s $name wol d"
      ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", ATTR{device/power/wakeup}="disabled"
      
      # Disable bluetooth wake (might be causing "early wake event")
      ACTION=="add", SUBSYSTEM=="bluetooth", ATTR{power/wakeup}="disabled"
    '';

    # OpenRGB
    udev.packages = [ pkgs-unstable.openrgb ];

    ollama = {
      enable = true;
      package = pkgs-unstable.ollama-cuda;
      loadModels = [ "mistral" ];
    };
  } else {});
  boot.kernelModules = if (host == "desktop") then [ "i2c-dev" "i2c-piix4" ] else []; # "nouveau" ];
  users.groups.i2c.members = [ username ];

  # Terminal command correction, alternative to thefuck, written in Rust
  programs.pay-respects = {
    enable = true;
    package = pkgs-stable.pay-respects;
    aiIntegration = {
      locale = "en-nz";
      model = "mistral:latest";
      url = "http://127.0.0.1:11434/v1/chat/completions";
    };
    alias = "f";
  };
}