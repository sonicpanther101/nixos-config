{ host, config, pkgs-stable, ... }:{

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      timeout = 5;
      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiSupport = true;
        useOSProber = if (host == "laptop-2") then true else false;
        memtest86.enable = true;
        timeoutStyle = "menu";
      };
    };

    # Styling bootloader
    loader.grub2-theme = {
      enable = true;
      theme = "stylish";
      footer = true;
      splashImage = pkgs-stable.fetchurl {
        url = "https://raw.githubusercontent.com/sonicpanther101/wallpapers/refs/heads/main/others/nixos-catppuccin.png";
        sha256 = "sha256-BWiy7wLWHHPjvvElEbdJt75ht/lZtJMi/LlnPeaV0XM=";
      };
    };

    # For windows filesystems to work
    supportedFilesystems = [ "ntfs" ];

    # Getting sleep to work
    kernelParams = [ "acpi_enforce_resources=lax" ] ++ (if (host == "desktop") then [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" "usbcore.autosuspend=1" ] else []);

  } // (if (host == "desktop") then {

    # Getting sleep to stay
    postBootCommands = ''
      echo PTXH > /proc/acpi/wakeup
    '';

    # XBox controller
    extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];
    extraModprobeConfig = ''
      options bluetooth disable_ertm=Y
    '';

    # OpenRGB
    kernelModules = [ "i2c-dev" ];
  } else {});

  # Sleep config
  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "30m";
    SuspendState = "mem";
  };
}