{ host, pkgs-unstable, lib, username, ... } : {

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
  boot.kernelParams = [ "acpi_enforce_resources=lax" ] ++ (if (host == "desktop") then ["nvidia.NVreg_PreserveVideoMemoryAllocations=1"] else []);

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "nz";
    variant = "";
  };

  # syncthing
  services.syncthing = {
    openDefaultPorts = true; # Open ports in the firewall for Syncthing. (NOTE: this will not open syncthing gui port)
  };
  # port 8384 is the default port to allow syncthing GUI access from the network.
  networking.firewall.allowedTCPPorts = [ 8384 ];

  # nvidia
  services.xserver.videoDrivers = if (host == "desktop") then ["nvidia"] else [];  

  # Stop keypresses and mouse movement turning on from sleep.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="1532", ATTRS{idProduct}=="00c5", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0361", ATTR{power/wakeup}="disabled"
    SUBSYSTEMS=="usb|hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0361", TAG+="uaccess", TAG+="Keychron V6"
  '';

  # OpenRGB
  services.udev.packages = [ pkgs-unstable.openrgb ];
  boot.kernelModules = if (host == "desktop") then [ "i2c-dev" "i2c-piix4" ] else []; # "nouveau" ];
  users.groups.i2c.members = [ username ];

  # Auto start hyprland
  services = {
    displayManager.autoLogin = {
      enable = true;
      user = "${username}";
    };
  };
}