{ inputs, config, pkgs, lib, ... }:
{
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;

  #boot.loader.grub = { ... };
  #boot.loader.grub2-theme = {
  #  enable = true;
  #  theme = "stylish";
  #  footer = true;
  #};
}
