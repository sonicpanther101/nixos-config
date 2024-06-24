{ ... }: 
{
  services = {
    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;
    dbus.enable = true;
    fstrim.enable = true;
    redshift = {
      enable = true;
      brightness = {
        day = "1";
        night = "0.7";
      };
      temperature.night = 1501;
    };
  };
  location.latitude = -41.51;
  location.longitude = 173.95;
  services.logind.extraConfig = ''
    # don’t shutdown when power button is short-pressed
    HandlePowerKey=ignore\n
    HandleLidSwitchDocked=suspend
  '';
}
