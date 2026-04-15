{ ... } : {
  security = {
    rtkit.enable = true;
    pam.services.swaylock = {
      enable = true;
    };
    polkit.enable = true;
  };
}