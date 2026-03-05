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
        hostName = "10.194.64.4";
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