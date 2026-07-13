{ host, inputs, username, pkgs-stable, pkgs-unstable, config, lib, ... } : {

  # Define a user account.
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [
      "networkmanager"
      "wheel"
    ] ++ lib.optionals (host == "laptop") [
      "surface-control"
    ] ++ lib.optionals config.my.isHighPower [
      "input"
      "video"
      "docker"
    ];
    shell = pkgs-stable.zsh;
  };

  imports = [ inputs.home-manager.nixosModules.home-manager ];
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = [];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { 
      inherit inputs username host pkgs-stable pkgs-unstable;
      isLaptop   = config.my.isLaptop;
      hasNvidia  = config.my.hasNvidia;
      isHighPower = config.my.isHighPower;
      isDualBoot = config.my.isDualBoot;
    };
    users.${username} = {
      imports = [ 
        ./../home
        inputs.catppuccin.homeModules.catppuccin
        inputs.walker.homeManagerModules.default
        inputs.chaotic.homeManagerModules.default
      ];

      programs.home-manager.enable = true;
      home.username = "${username}";
      home.homeDirectory = "/home/${username}";
      home.stateVersion = "25.05";
    };
  };
}