{ pkgs-stable, ... } : {
  # 1. Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PubkeyAuthentication = true;
    };
  };

  # 2. Create a dedicated nix builder user
  users.users.nix-remote-builder = {
    isSystemUser = true;
    group = "nix-remote-builder";
    shell = pkgs-stable.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 j4ipuxFc64gS4stnaY0IWlaaldBlZ4H8dk+JQQb3rQI"
    ];
  };

  users.groups.nix-remote-builder = {};

  # 3. Trust this user in the nix daemon
  nix.settings.trusted-users = [ "root" "nix-remote-builder" ];
}