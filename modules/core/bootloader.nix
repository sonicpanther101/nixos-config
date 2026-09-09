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
    # PTXH = a Thunderbolt/USB4 host controller (NOT enp6s0 — verified via
    # `readlink -f /sys/class/net/enp6s0/device`, which resolves under PT29,
    # not PTXH). Kept DISABLED as before, it was an earlier fix for spurious
    # wake from that device.
    # XHC0 = USB3 controller — kept DISABLED, confirmed to be causing
    # spurious immediate wake-from-suspend.
    # `echo <name>` toggles state rather than setting it, so these are
    # guarded to be idempotent across reboots.
    postBootCommands = ''
      grep -q "PTXH.*enabled" /proc/acpi/wakeup && echo PTXH > /proc/acpi/wakeup
      grep -q "XHC0.*enabled" /proc/acpi/wakeup && echo XHC0 > /proc/acpi/wakeup
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
