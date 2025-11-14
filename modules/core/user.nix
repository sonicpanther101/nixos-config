{ host, inputs, username, pkgs-stable, pkgs-unstable, ... } : {

  # Define a user account.
  users.users.adam = {
    isNormalUser = true;
    description = "adam";
    extraGroups = [
      "networkmanager"
      "wheel"
    ] ++ (if (host == "laptop") then [
      "surface-control"
    ] else []);
  };

  imports = [ inputs.home-manager.nixosModules.home-manager ];
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = [];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs username host pkgs-stable pkgs-unstable; };
    users.adam = {
      imports = [ ./../home ];

      programs.home-manager.enable = true;
      home.username = "adam";
      home.homeDirectory = "/home/adam";
      home.stateVersion = "25.05";
    };
  };
}