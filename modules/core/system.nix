{ self, pkgs, lib, inputs, username, host, ...}: 
{
  config = {
    services.iptsd.enable = 
      if (host == "laptop") then
        true
      else false;
    # imports = [ inputs.nix-gaming.nixosModules.default ];
    nix = {
      settings = {
        auto-optimise-store = true;
        experimental-features = [ "nix-command" "flakes" ];
        substituters = [ "https://nix-gaming.cachix.org" ];
        trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };
    nixpkgs = {
      overlays = [
        self.overlays.default
        inputs.nur.overlay
      ];
    };

    environment.systemPackages = with pkgs; [
      wget
      git
    ];

    time.timeZone = "Pacific/Auckland";
    i18n.defaultLocale = "en_US.UTF-8";
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "23.05";

    system.activationScripts = 
      if (host == "desktop") then {
        script.text = ''
          install -d -m 755 /home/${username}/open-webui/data -o root -g root
        '';
      }
      else {};
  };
}