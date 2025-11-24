{
  description = "Sonicpanther101's nixos configuration";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    erosanix = {
      url = "github:emmanuelrosa/erosanix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    home-manager.url = "github:nix-community/home-manager";

    hyprland = {
      url = "github:hyprwm/Hyprland";
    };

    stylix.url = "github:danth/stylix";

    catppuccin-bat = {
      url = "github:catppuccin/bat";
      flake = false;
    };
    catppuccin-cava = {
      url = "github:catppuccin/cava";
      flake = false;
    };
    catppuccin-starship = {
      url = "github:catppuccin/starship";
      flake = false;
    };
  };

  outputs = { self, nixpkgs-unstable, nixpkgs-stable, erosanix, ... } @ inputs:
  let
    username = "adam";
    system = "x86_64-linux";
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };
    lib = nixpkgs-unstable.lib;
  in {
    nixosConfigurations = {
      desktop = nixpkgs-unstable.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/desktop
          inputs.stylix.nixosModules.stylix
        ];
        specialArgs = {
          host="desktop";
          inherit self inputs username pkgs-stable pkgs-unstable;
        };
      };
      laptop = nixpkgs-unstable.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/laptop
          inputs.stylix.nixosModules.stylix
        ];
        specialArgs = {
          host="laptop";
          inherit self inputs username pkgs-stable pkgs-unstable;
        };
      };
    };
  };
}
