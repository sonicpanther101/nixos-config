{ host, ... }: {
  networking = {
    hostName = host;
    networkmanager = {
      enable = true;
      dns = "none"; # Prevent NetworkManager from overriding DNS
    };
    # Point to local NextDNS proxy
    nameservers = [ "127.0.0.1" "::1" ];
  };
}