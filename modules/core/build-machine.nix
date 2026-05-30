# ─────────────────────────────────────────────────────────────────────────────
# BUILD MACHINE — Remote build server setup
#
# Run these steps ONCE on the machine you want to act as the build server:
#
#   STEP 1 — Generate a dedicated SSH key for the builder user:
#     sudo ssh-keygen -t ed25519 \
#       -f /etc/nix/remote-build-key \
#       -N "" \
#       -C "nix-remote-builder@$(hostname)"
#
#   STEP 2 — Lock down permissions:
#     sudo chmod 600 /etc/nix/remote-build-key
#     sudo chmod 644 /etc/nix/remote-build-key.pub
#
#   STEP 3 — Print the public key, then paste it into `authorizedKeys` below:
#     sudo cat /etc/nix/remote-build-key.pub
#
#   STEP 4 — Rebuild this machine:
#     my-install
#
#   STEP 5 — Get this machine's IP for use in weak-machine.nix:
#     ip -4 addr show | grep inet
#
# ─────────────────────────────────────────────────────────────────────────────
{ pkgs-stable, lib, config, ... }: {

  services.openssh = lib.mkIf config.my.isHighPower {
    enable = true;
    settings.PubkeyAuthentication = true;
  };

  users.users.nix-remote-builder = lib.mkIf config.my.isHighPower {
    isSystemUser = true;
    group = "nix-remote-builder";
    shell = pkgs-stable.bash;
    openssh.authorizedKeys.keys = [
      # Paste the output of `sudo cat /etc/nix/remote-build-key.pub` here
      # Example: "ssh-ed25519 AAAA... nix-remote-builder@surface"
      ""
    ];
  };

  users.groups.nix-remote-builder = lib.mkIf config.my.isHighPower {};

  nix.settings.trusted-users = lib.mkIf config.my.isHighPower [ "root" "nix-remote-builder" ];
}