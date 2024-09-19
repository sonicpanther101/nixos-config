{
  description = "FrostPhoenix's nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  
    hypr-contrib.url = "github:hyprwm/contrib";
    hyprpicker.url = "github:hyprwm/hyprpicker";
  
    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
  
    nix-gaming.url = "github:fufexan/nix-gaming";
  
    hyprland = {
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
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

    stylix.url = "github:danth/stylix";

    swww.url = "github:LGFae/swww";
  };

  outputs = { nixpkgs, self, grub2-themes, catppuccin, nixos-hardware, ...} @ inputs:
  let
    selfPkgs = import ./pkgs;
    username = "adam";
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    lib = nixpkgs.lib;
  in
  {
    overlays.default = selfPkgs.overlay;
    nixosConfigurations = {
      laptop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ 
          (import ./hosts/laptop) 
          # grub2-themes.nixosModules.default
          catppuccin.nixosModules.catppuccin
          inputs.stylix.nixosModules.stylix
          # nixos-hardware.nixosModules.microsoft-surface-pro-intel
          # catppuccin.homeManagerModules.catppuccin
        ];
        specialArgs = { host="laptop"; inherit self inputs username ; };
      };
      desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ (import ./hosts/desktop) 
                    # inputs.grub2-themes.nixosModules.default
                    inputs.stylix.nixosModules.stylix
                    ];
        specialArgs = { host="desktop"; inherit self inputs username ; };
      };
    };
  };
}
