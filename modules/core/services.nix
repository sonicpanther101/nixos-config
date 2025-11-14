{ host, ... } : {

  # getting sleep to work
  services.power-profiles-daemon.enable = true;
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandlePowerKey = if (host == "desktop") then "
      suspend-then-hibernate
    " else "
      ignore
    ";
    HandlePowerKeyLongPress = "poweroff";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "nz";
    variant = "";
  };

  services.syncthing = {
    openDefaultPorts = true; # Open ports in the firewall for Syncthing. (NOTE: this will not open syncthing gui port)
  };
  # port 8384 is the default port to allow syncthing GUI access from the network.
  networking.firewall.allowedTCPPorts = [ 8384 ];

  services.xserver.videoDrivers = if (host == "desktop") then ["nvidia"] else [];
}