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
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    stylix = {
      url = "github:danth/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    catppuccin.url = "github:catppuccin/nix";

    hyprland.url = "github:hyprwm/Hyprland/91f29f23bb691462f8aa6171b964069aebc37910"; # pinned for dependancy fix (go back to versions when possible)

    waybar-git = {
      url = "github:Alexays/Waybar/16843896794a9c595139318420f81f40e84f8c78";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    split-monitor-workspaces = {
      url = "github:zjeffer/split-monitor-workspaces/v0.56.2";
      inputs.hyprland.follows = "hyprland";
    };

    hyprgrass = {
      url = "github:horriblename/hyprgrass/d094a3e62f6ecaeb41515982d3e13edefaf8a4e7";
      inputs.hyprland.follows = "hyprland";
    };
    
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    
    nix-index-database.url = "github:nix-community/nix-index-database";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    grub2-themes.url = "github:vinceliuice/grub2-themes";

    # Declarative NixOS microVMs (the sandbox for OpenCode)
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
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
          inputs.microvm.nixosModules.host
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
      # The OpenCode sandbox VM. The attribute name must match microvm.vms.<name>.
      agent = nixpkgs-stable.lib.nixosSystem {
        inherit system;
        modules = [
          inputs.microvm.nixosModules.microvm
          ./modules/core/agent-vm/guest.nix
        ];
        specialArgs = { inherit inputs; };
      };
      laptop-1 = nixpkgs-stable.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/laptop-1
          inputs.grub2-themes.nixosModules.default
          inputs.stylix.nixosModules.stylix
          inputs.nix-index-database.nixosModules.default
          inputs.nur.modules.nixos.default
          inputs.chaotic.nixosModules.default
          inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
        ];
        specialArgs = {
          host = "laptop-1";
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
