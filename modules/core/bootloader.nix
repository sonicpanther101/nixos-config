{ inputs, config, pkgs-unstable, pkgs-stable, lib, host, ... }:{

  boot.loader = {
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
  boot.supportedFilesystems = [ "ntfs" ];

  # Sleep config
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';

  # OpenRGB
  boot.kernelModules = [ "i2c-dev" ];
}