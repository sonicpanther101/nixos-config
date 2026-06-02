{ lib, pkgs-unstable, pkgs-stable, username, config, ... } : {
  
  services = {

    # Bluetooth UI
    blueman.enable = true;

    # Getting sleep to work
    logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandlePowerKey = "ignore";
      HandlePowerKeyLongPress = "poweroff";
    };

    greetd = {
      enable = true;

      settings = {
        default_session = {
          user = username;

          command = ''
            start-hyprland
          '';
        };
      };
    };

    # Configure keymap in X11
    xserver.xkb = {
      layout = "nz";
      variant = "";
    };

    # for zeal docs: flatpak run org.zealdocs.Zeal
    # for bambu studio: flatpak run com.bambulab.BambuStudio
    # for cura: flatpak run com.ultimaker.cura
    flatpak = {
      enable = true;
    };
    
    # For nemo trash
    gvfs.enable = true;

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
  } // (lib.optionalAttrs config.my.isLaptop {

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

    # Throttles CPU when it gets too hot
    thermald = {
      enable = true;
      configFile = ./thermal-conf.xml;
    };

    input-remapper.enable = true;
    
  }) // (lib.optionalAttrs config.my.hasNvidia {
    xserver.videoDrivers = ["nvidia"];  
  }) // (lib.optionalAttrs config.my.isHighPower {

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
      
      # Disable bluetooth wake (might be causing "early wake event")
      ACTION=="add", SUBSYSTEM=="bluetooth", ATTR{power/wakeup}="disabled"
    '';

    # OpenRGB
    udev.packages = [ pkgs-unstable.openrgb ];

    sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;   # needed for virtual display/input capture
      openFirewall = true;
    };

    ollama = {
      enable = true;
      package = pkgs-unstable.ollama-cuda;
      loadModels = [ "mistral" "qwen2.5-coder:14b" "qwen3:14b-q4_K_M" ];
      environmentVariables = {
        OLLAMA_NO_CLOUD = "1";
        OLLAMA_KEEP_ALIVE = "1h";
        OLLAMA_NUM_PARALLEL = "1";
        OLLAMA_MAX_LOADED_MODELS = "1";
      };
    };

    open-webui = {
      enable = true;
      port = 8080;
      host = "127.0.0.1";
      environment = {
        OLLAMA_BASE_URL = "http://127.0.0.1:11434";
        # Enable RAG features
        ENABLE_RAG_WEB_SEARCH = "true";
        ENABLE_RAG_LOCAL_WEB_FETCH = "true";
        # Chunk settings for better context
        CHUNK_SIZE = "1500";
        CHUNK_OVERLAP = "100";

        OLLAMA_REQUEST_TIMEOUT = "600";

        # Tools / functions
        ENABLE_COMMUNITY_SHARING = "false";
        ENABLE_TOOLS = "true";

        # Disable telemetry
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
      };
    };
  });
  boot.kernelModules = lib.mkIf config.my.isHighPower [ "i2c-dev" "i2c-piix4" ]; # "nouveau" ];
  users.groups.i2c.members = [ username ];

  # Terminal command correction, alternative to thefuck, written in Rust
  programs.pay-respects = {
    enable = true;
    package = pkgs-stable.pay-respects;
    aiIntegration = lib.mkIf config.my.isHighPower {
      locale = "en-nz";
      model = "mistral:latest";
      url = "http://127.0.0.1:11434/v1/chat/completions";
    };
    alias = "f";
  };
}