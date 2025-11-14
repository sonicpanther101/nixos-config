{ ... } : {

  programs.git = {
    enable = true;
    settings = {
      user = {
        name  = "sonicpanther101";
        email = "sonicpanther101@gmail.com";
      };
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 10";
    flake = "/home/adam/nixos-config#desktop";
  };
}