{ pkgs, host,  ... }: 
{
  # getting sleep to work
  services.power-profiles-daemon.enable = true;
  services.logind = {
    lidSwitch = "suspend-then-hibernate";
    powerKey = if (host == "desktop") then "
      suspend-then-hibernate
    " else "
      ignore
    ";
    powerKeyLongPress = "poweroff"
  };

  environment.sessionVariables = {
    # If your cursor becomes invisible
    WLR_NO_HARDWARE_CURSORS = "1";
    # Hint electron apps to use wayland
    NIXOS_OZONE_WL = "1";
  };
}