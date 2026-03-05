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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAmv+o+DPuko64iLKsGUXs8LVUsD3EEZ82iZPaLdh+bY nix-remote-builder@surface"
    ];
  };

  users.groups.nix-remote-builder = {};

  # 3. Trust this user in the nix daemon
  nix.settings.trusted-users = [ "root" "nix-remote-builder" ];
}