{ config, pkgs-stable, lib, ... }:{

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      timeout = 5;
      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiSupport = true;
        useOSProber = config.my.isDualBoot;
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
    kernelParams = [ "acpi_enforce_resources=lax" ] ++ lib.optionals config.my.hasNvidia [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" "usbcore.autosuspend=1" ];

  } // lib.optionalAttrs config.my.isHighPower {

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
  };

  # Sleep config
  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "30m";
    SuspendState = "mem";
  };
}