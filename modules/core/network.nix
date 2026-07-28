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
      # Calendar server
      allowedTCPPorts = [ 5232 ];
      # Wake on lan
      allowedUDPPorts = lib.mkIf config.my.isHighPower [ 9 ];
    };
    # Point to local NextDNS proxy
    nameservers = [ "127.0.0.1" "::1" ];
  };

  environment.etc."systemd/system-sleep/reload-rtw88.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      # Reload rtw88_8821ce after resume to work around wifi not
      # reassociating after long suspends.
      case "$1" in
        post)
          modprobe -r rtw88_8821ce
          sleep 1
          modprobe rtw88_8821ce
          ;;
      esac
    '';
  };
}
