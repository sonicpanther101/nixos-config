# ─────────────────────────────────────────────────────────────────────────────
# WEAK MACHINE — Offloads nix builds to a remote build server
#
# Complete the build-machine.nix setup on the server first, then:
#
#   STEP 1 — Copy the build key from the server to this machine:
#     (Run on the SERVER, replacing <this-machine-ip> with this machine's IP)
#     sudo scp /etc/nix/remote-build-key <your-user>@<this-machine-ip>:/etc/nix/remote-build-key
#     sudo scp /etc/nix/remote-build-key.pub <your-user>@<this-machine-ip>:/etc/nix/remote-build-key.pub
#
#   STEP 2 — Lock down permissions on THIS machine:
#     sudo chmod 600 /etc/nix/remote-build-key
#     sudo chown root:root /etc/nix/remote-build-key
#
#   STEP 3 — Fill in the server's IP below (hostName field):
#     ip -4 addr show   ← run this on the server to find its IP
#
#   STEP 4 — Register the server host key on this machine (run as root):
#     sudo ssh-keyscan -t ed25519 <server-ip> | sudo tee -a /root/.ssh/known_hosts
#
#   STEP 5 — Test the connection before rebuilding:
#     sudo nix store ping --store \
#       "ssh-ng://nix-remote-builder@<server-ip>?ssh-key=/etc/nix/remote-build-key"
#     (Should print: Trusted: 1)
#
#   STEP 6 — Rebuild this machine:
#     my-install
#
# ─────────────────────────────────────────────────────────────────────────────
{ config, lib, ... }: {
  nix = lib.mkIf config.my.isLaptop {
    distributedBuilds = true;

    extraOptions = ''
      builders-use-substitutes = true
    '';

    # Fast timeout so offline desktop fails immediately rather than hanging
    settings = {
      connect-timeout = 8;
      fallback = true;
    };

    buildMachines = [
      {
        hostName = ""; # ← Paste the server's IP here (e.g. "192.168.1.50")
        system = "x86_64-linux";
        protocol = "ssh-ng";
        sshUser = "nix-remote-builder";
        sshKey = "/etc/nix/remote-build-key";
        maxJobs = 8;       # Adjust to match the server's core count
        speedFactor = 10;
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      }
    ];
  };
}