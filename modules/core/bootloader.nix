{ config, pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.grub = {
    extraConfig = "set theme=($drive2)${pkgs.breeze-grub}/grub/themes/breeze/theme.txt";
    splashImage = null;
  };
}
