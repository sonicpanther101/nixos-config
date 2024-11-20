{ inputs, config, pkgs, lib, host, ... }:
{
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.supportedFilesystems = ["ntfs"];

  boot.extraModprobeConfig = 
    if (host == "laptop") then 
      ''
        options snd-intel-dspcfg dsp_driver=1
      ''
    else '''';

  # boot.kernelPatches = [{
  #   patch = ./cam.patch;
  #   name = "surfacepro3-cameras"; 
  # }];

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
