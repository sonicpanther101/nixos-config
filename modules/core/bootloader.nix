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
      extraEntries = if (host == "desktop") then ''
          menuentry "AthenaOS" {
            chainloader (hd1,0)+1
          }
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
}
