{
  description = "FrostPhoenix's nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  
    hypr-contrib.url = "github:hyprwm/contrib";
    hyprpicker.url = "github:hyprwm/hyprpicker";
  
    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
  
    nix-gaming.url = "github:fufexan/nix-gaming";
  
    hyprland-laptop = {
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
      rev = "c86db7bbb0cf14d4955ee3a4d13c0ed9f8a0e0ae";
      submodules = true;
    };

    hyprland-desktop = {
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
      rev = "9a09eac79b85c846e3a865a9078a3f8ff65a9259";
      submodules = true;
    };
  
    home-manager.url = "github:nix-community/home-manager";

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

    catppuccin.url = "github:catppuccin/nix";

    grub2-themes = {
      url = "github:sonicpanther101/grub2-themes";
    };

    ags.url = "github:Aylur/ags";
    astal.url = "github:Aylur/astal";

    stylix.url = "github:danth/stylix";

    impurity.url = "github:outfoxxed/impurity.nix";
    thorium.url = "github:end-4/nix-thorium";

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.nixpkgs.follows = "hyprland-desktop";
    };

    hyprsplit = {
      url = "github:shezdy/hyprsplit/main";
      inputs.hyprland.follows = "hyprland-desktop";
    };

    matugen = {
      url = "github:/InioX/Matugen";
      # ref = "refs/tags/matugen-v0.10.0"
    };
  };

  outputs = { nixpkgs, nixpkgs-stable, self, grub2-themes, ...} @ inputs:
  let
    username = "adam";
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };
    lib = nixpkgs.lib;
  in
  {
    nixosConfigurations = {
      laptop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (import ./hosts/laptop) 
          inputs.grub2-themes.nixosModules.default
          inputs.catppuccin.nixosModules.catppuccin
          inputs.stylix.nixosModules.stylix
          # inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
          # inputs.catppuccin.homeManagerModules.catppuccin
        ];
        specialArgs = { 
          host="laptop"; 
          inherit self inputs username pkgs-stable; 
        };
      };
      desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (import ./hosts/desktop) 
          grub2-themes.nixosModules.default
          inputs.stylix.nixosModules.stylix
          inputs.chaotic.homeManagerModules.default
        ];
        specialArgs = {
          host="desktop";
          inherit self inputs username pkgs-stable;
        };
      };
    };
  };
}
