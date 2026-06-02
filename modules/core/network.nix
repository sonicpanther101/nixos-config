{ host, lib, config, ... }: {
  networking = {
    hostName = host;
    networkmanager = {
      enable = true;
      dns = "none"; # Prevent NetworkManager from overriding DNS
    };
    # Wake on lan
    interfaces.enp6s0.wakeOnLan.enable = config.my.isHighPower;
    # port 8384 is the default port to allow syncthing GUI access from the network.
    firewall = {
      enable = true;
      # Wake on lan
      allowedUDPPorts = lib.mkIf config.my.isHighPower [ 9 ];
    };
    # Point to local NextDNS proxy
    nameservers = [ "127.0.0.1" "::1" ];
  };
}