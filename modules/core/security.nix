{ username, ... } : {
  security = {
    rtkit.enable = true;
    pam.services.hyprlock = {
      enable = true;
    };
    polkit.enable = true;
  };
}