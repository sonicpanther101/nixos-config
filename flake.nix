{
  description = "Sonicpanther101's nixos configuration";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";

    erosanix = {
      url = "github:emmanuelrosa/erosanix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
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

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    split-monitor-workspaces = {
      url = "github:zjeffer/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
    
    hyprshutdown.url = "github:hyprwm/hyprshutdown";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    
    nix-index-database.url = "github:nix-community/nix-index-database";

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
          "ventoy-gtk3-1.1.10"
          "qtwebengine-5.15.19"
        ];
      };
    };
  in {
    nixosConfigurations = {
      desktop = nixpkgs-unstable.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/desktop
          inputs.grub2-themes.nixosModules.default
          inputs.stylix.nixosModules.stylix
          inputs.nix-index-database.nixosModules.default
        ];
        specialArgs = {
          host = "desktop";
          inherit self inputs username pkgs-stable pkgs-unstable;
        };
      };
      laptop = nixpkgs-unstable.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/laptop
          inputs.grub2-themes.nixosModules.default
          inputs.stylix.nixosModules.stylix
          inputs.nix-index-database.nixosModules.default
          inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
        ];
        specialArgs = {
          host = "laptop";
          inherit self inputs username pkgs-stable pkgs-unstable;
        };
      };
      laptop-2 = nixpkgs-unstable.lib.nixosSystem {
      	inherit system;
        modules = [
          ./hosts/laptop-2
          inputs.grub2-themes.nixosModules.default
          inputs.stylix.nixosModules.stylix
          inputs.nix-index-database.nixosModules.default
        ];
        specialArgs = {
          host = "laptop-2";
          inherit self inputs username pkgs-stable pkgs-unstable;
        };
      };
    };
  };
}
