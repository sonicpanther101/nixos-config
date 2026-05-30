{ host, inputs, username, pkgs-stable, pkgs-unstable, config, ... } : {

  # Define a user account.
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [
      "networkmanager"
      "wheel"
    ] ++ (if (host == "laptop") then [
      "surface-control"
    ] else if config.my.isHighPower then [
      "input"
      "video"
    ] else []);
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
        inputs.sops-nix.homeManagerModules.sops
      ];

      sops = {
        age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
        defaultSopsFile = ../../secrets/secrets.yaml;  # path to your secrets file

        secrets.wakatime_api_key = {};  # declares the secret
      };

      programs.home-manager.enable = true;
      home.username = "${username}";
      home.homeDirectory = "/home/${username}";
      home.stateVersion = "25.05";
    };
  };
}