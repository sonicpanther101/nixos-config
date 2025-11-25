{ username, host, ... } : {

  programs.nh = {
    enable = true;
    clean.enable = true;
  };

  # Temporary notifications daemon to shut grimblast up
  services.mako.enable = true;
}