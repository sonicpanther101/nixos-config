{ pkgs, config, lib, ... }:
{
  services = {
    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;
    dbus.enable = true;
    fstrim.enable = true;
  };
  services.logind.extraConfig = ''
    # don’t shutdown when power button is short-pressed
    HandlePowerKey=ignore
  '';
  services.hardware.openrgb.enable = true;
  #services.ollama = {
  #  enable = true;
  #  acceleration = "cuda";
  #};
  #services = {
  #  udev.packages = with pkgs; [ 
  #    openrgb-with-all-plugins
  #  ];
  #};
}
