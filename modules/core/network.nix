{ host, ... } : {
  networking = {
    hostName = host; # Define your hostname.
    wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable networking
    networkmanager.enable = true;

    # Set nextdns as network dns for all adblocking
    nameservers = [ "176a88.dns.nextdns.io" ];
  };
}