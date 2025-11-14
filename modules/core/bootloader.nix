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

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';

}