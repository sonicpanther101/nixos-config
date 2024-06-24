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
  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };
  services.udev.extraRules = builtins.readFile ./60-openrgb.rules;
}
