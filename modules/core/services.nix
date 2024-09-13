{ pkgs, ... }: 
{
  services.ollama.enable = true;
  services = {
    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;
    dbus.enable = true;
    fstrim.enable = true;
  };
  services.logind = {
    lidSwitch = "suspend-then-hibernate";
    extraConfig = ''
      HandlePowerKey=ignore
      HandleLidSwitchDocked=suspend-then-hibernate
    '';
  };
  systemd.sleep.extraConfig = "HibernateDelaySec=2h";

  systemd.packages = [
    pkgs.iptsd
  ];
  services.udev.packages = [
    pkgs.iptsd
  ];
}
