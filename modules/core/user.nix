{ host, inputs, username, pkgs-stable, pkgs-unstable, config, lib, ... } : {

  # Define a user account.
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [
      "networkmanager"
      "wheel"
      "plugdev"
    ] ++ lib.optionals (host == "laptop-1") [
      "surface-control"
    ] ++ lib.optionals config.my.isHighPower [
      "input"
      "video"
      "docker"
    ] ++ lib.optionals config.my.hasPinLogin [
      "input"
    ];
    shell = pkgs-stable.zsh;
  };

  # Needed for `openhands serve` (and anything else Docker-based).
  # Gated on isHighPower to match the "docker" group above.
  virtualisation.docker.enable = config.my.isHighPower;

  imports = [ inputs.home-manager.nixosModules.home-manager ];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { 
      inherit inputs username host pkgs-stable pkgs-unstable;
      isLaptop   = config.my.isLaptop;
      hasNvidia  = config.my.hasNvidia;
      isHighPower = config.my.isHighPower;
      isDualBoot = config.my.isDualBoot;
      hasPinLogin = config.my.hasPinLogin;
      pinLoginLength = config.my.pinLoginLength;
    };
    users.${username} = {
      imports = [ 
        ./../home
        inputs.catppuccin.homeModules.catppuccin
        inputs.chaotic.homeManagerModules.default
      ];

      programs.home-manager.enable = true;
      home.username = "${username}";
      home.homeDirectory = "/home/${username}";
      home.stateVersion = "25.05";
    };
  };
}
