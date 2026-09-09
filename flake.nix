{
  description = "Sonicpanther101's nixos configuration";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    erosanix = {
      url = "github:emmanuelrosa/erosanix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    catppuccin.url = "github:catppuccin/nix";

    hyprland.url = "github:hyprwm/Hyprland/v0.55.4"; 

    split-monitor-workspaces = {
      url = "github:zjeffer/split-monitor-workspaces/v0.55.4";
      inputs.hyprland.follows = "hyprland";
    };

    hyprgrass = {
      url = "github:horriblename/hyprgrass/d094a3e62f6ecaeb41515982d3e13edefaf8a4e7";
      inputs.hyprland.follows = "hyprland";
    };
    
    hyprshutdown.url = "github:hyprwm/hyprshutdown";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    
    nix-index-database.url = "github:nix-community/nix-index-database";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    grub2-themes.url = "github:vinceliuice/grub2-themes";
  };

  outputs = { self, nixpkgs-unstable, nixpkgs-stable, ... } @ inputs:
  let
    username = "adam";
    system = "x86_64-linux";
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config = {
        allowUnfree = true;

        permittedInsecurePackages = [
          "qtwebengine-5.15.19"
        ];
      };
      overlays = [
        (final: prev: {
          pkgsi686Linux = prev.pkgsi686Linux.extend (final32: prev32: {
            openldap = prev32.openldap.overrideAttrs (old: {
              doCheck = false;
            });
          });
        })
      ];
    };
    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config = {
        allowUnfree = true;

        permittedInsecurePackages = [
          "ventoy-gtk3-1.1.12"
          "qtwebengine-5.15.19"
        ];
      };
    };
  in {
    nixosConfigurations = {
      desktop = nixpkgs-stable.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/desktop
          inputs.grub2-themes.nixosModules.default
          inputs.stylix.nixosModules.stylix
          inputs.nix-index-database.nixosModules.default
          inputs.nur.modules.nixos.default
          inputs.chaotic.nixosModules.default
        ];
        specialArgs = {
          host = "desktop";
          inherit self inputs username pkgs-stable pkgs-unstable;
        };
      };
      laptop = nixpkgs-stable.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/laptop
          inputs.grub2-themes.nixosModules.default
          inputs.stylix.nixosModules.stylix
          inputs.nix-index-database.nixosModules.default
          inputs.nur.modules.nixos.default
          inputs.chaotic.nixosModules.default
          inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
        ];
        specialArgs = {
          host = "laptop";
          inherit self inputs username pkgs-stable pkgs-unstable;
        };
      };
      laptop-2 = nixpkgs-stable.lib.nixosSystem {
      	inherit system;
        modules = [
          ./hosts/laptop-2
          inputs.grub2-themes.nixosModules.default
          inputs.stylix.nixosModules.stylix
          inputs.nix-index-database.nixosModules.default
          inputs.nur.modules.nixos.default
          inputs.chaotic.nixosModules.default
        ];
        specialArgs = {
          host = "laptop-2";
          inherit self inputs username pkgs-stable pkgs-unstable;
        };
      };
    };
  };
}
