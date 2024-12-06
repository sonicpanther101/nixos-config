{ inputs, config, pkgs, lib, host, ... }:
{
  boot.loader.efi.canTouchEfiVariables = true;
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
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

  # boot.loader.grub = { ... };
  boot.loader.grub2-theme = {
    enable = true;
    theme = "stylish";
    footer = true;
  };
}
