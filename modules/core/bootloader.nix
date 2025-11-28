{ inputs, host, config, ... }:{

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiSupport = true;
        useOSProber = false;
        memtest86.enable = true;
      };
    };

    # For windows filesystems to work
    supportedFilesystems = [ "ntfs" ];

    # OpenRGB
    kernelModules = if (host == "desktop") then [ "i2c-dev" ] else [];

  } // (if (host == "desktop") then {

    # XBox controller
    extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];
    extraModprobeConfig = ''
      options bluetooth disable_ertm=Y
    '';
  } else {});

  # Sleep config
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';
}