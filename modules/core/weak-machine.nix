{
  nix = {
    distributedBuilds = true;

    # This tells nix to prefer fetching results from
    # substituters on the builder rather than re-downloading
    extraOptions = ''
      builders-use-substitutes = true
    '';

    buildMachines = [
      {
        hostName = ""; # PC IP
        system = "x86_64-linux";
        protocol = "ssh-ng";            # More efficient than plain ssh
        sshUser = "nix-remote-builder";
        sshKey = "/etc/nix/remote-build-key";
        maxJobs = 8;                    # Match your PC's core count
        speedFactor = 10;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
      }
    ];
  };
}

# On the surface, run this lot to register the host
# # Run as root so it goes into root's known_hosts
# sudo ssh-keyscan -t ed25519 YOUR_PC_IP_OR_HOSTNAME \
#   | sudo tee -a /root/.ssh/known_hosts

# # Verify the connection works as root before trusting Nix to use it
# sudo ssh -i /etc/nix/remote-build-key \
#   nix-remote-builder@YOUR_PC_IP \
#   "nix --version"

# To test:
# sudo nix store ping --store \
#   "ssh-ng://nix-remote-builder@PC_IP?ssh-key=/etc/nix/remote-build-key"
# You should see Trusted: 1