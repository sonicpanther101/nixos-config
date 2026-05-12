{ host, ... }: {
  networking = {
    hostName = host;
    networkmanager = {
      enable = true;
      dns = "none"; # Prevent NetworkManager from overriding DNS
    };
    # port 8384 is the default port to allow syncthing GUI access from the network.
    firewall.enable = true;
    # Point to local NextDNS proxy
    nameservers = [ "127.0.0.1" "::1" ];
  };
}