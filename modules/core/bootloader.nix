{ inputs, config, pkgs, lib, host, ... }:
{
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      useOSProber = false;
      memtest86.enable = true;
      extraEntries = if (host == "desktop") then ''
        '' else '''';
    };
  };
  boot.supportedFilesystems = ["ntfs"];

  boot.extraModprobeConfig = 
    if (host == "laptop") then 
      ''
        options snd-intel-dspcfg dsp_driver=1
      ''
    else '''';

  # catppuccin.enable = true;
  # catppuccin.accent = "blue";
  # catppuccin.flavor = "mocha";

  # boot.loader.grub.catppuccin = {
  #   enable = true;
  #   flavor = "mocha";
  # };

  boot.loader.grub2-theme = {
    enable = true;
    theme = "stylish";
    footer = true;
  };

  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = null;
      PermitRootLogin = "yes";
    };
  };
}
