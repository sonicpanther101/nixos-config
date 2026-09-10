{ host, lib, config, ... }: {
  networking = {
    hostName = host;
    networkmanager = {
      enable = true;
      dns = "none"; # Let NextDNS control the DNS instead
    };
    # Wake on lan
    interfaces.enp6s0.wakeOnLan.enable = config.my.isHighPower;
    # Point to local NextDNS proxy
    nameservers = [ "127.0.0.1" "::1" ];
    # nameservers = [ "1.1.1.1" "8.8.8.8" ];
    firewall = {
      enable = true;
      # Calendar server
      allowedTCPPorts = [ 5232 ];
      # Wake on lan
      allowedUDPPorts = lib.mkIf config.my.isHighPower [ 9 ];
    };
  };

  environment.etc."systemd/system-sleep/disable-acpi-wakeup.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      case "$1" in
        pre)
          for dev in PTXH XHC0; do
            grep -q "^$dev.*enabled" /proc/acpi/wakeup && echo "$dev" > /proc/acpi/wakeup
          done
          ;;
      esac
    '';
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
