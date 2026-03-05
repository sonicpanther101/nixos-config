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
      "" # get from: (looks like: ssh-ed25519 AAAA)
      # # Generate as root
      # sudo ssh-keygen -t ed25519 \
      #   -f /etc/nix/remote-build-key \
      #   -N "" \
      #   -C "nix-remote-builder@surface"

      # # Lock down permissions
      # sudo chmod 600 /etc/nix/remote-build-key
      # sudo chmod 644 /etc/nix/remote-build-key.pub

      # # Print the public key to copy to your PC
      # sudo cat /etc/nix/remote-build-key.pub
    ];
  };

  users.groups.nix-remote-builder = {};

  # 3. Trust this user in the nix daemon
  nix.settings.trusted-users = [ "root" "nix-remote-builder" ];
}