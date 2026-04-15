{ host, inputs, username, pkgs-stable, pkgs-unstable, ... } : {

  # Define a user account.
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [
      "networkmanager"
      "wheel"
    ] ++ (if (host == "laptop") then [
      "surface-control"
    ] else []);
    shell = pkgs-stable.zsh;
  };

  imports = [ inputs.home-manager.nixosModules.home-manager ];
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = [];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs username host pkgs-stable pkgs-unstable; };
    users.${username} = {
      imports = [ 
        ./../home
        inputs.catppuccin.homeModules.catppuccin
      ];

      catppuccin = {
        enable = true;
        accent = "blue";
        flavor = "mocha";

        hyprlock.enable = false;
      };

      programs.home-manager.enable = true;
      home.username = "${username}";
      home.homeDirectory = "/home/${username}";
      home.stateVersion = "25.05";
    };
  };
}