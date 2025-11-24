{ username, host, ... } : {

  programs.git = {
    enable = true;
    settings = {
      user = {
        name  = "sonicpanther101";
        email = "sonicpanther101@gmail.com";
      };
    };
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    flake = "/home/${username}/nixos-config#${host}";
  };
}