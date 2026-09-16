{ host, lib, config, pkgs-stable, ... }: {
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
      # Trust Docker's bridge entirely rather than allow-listing ports one at
      # a time. Needed because containers reaching host services (Ollama,
      # and OpenHands' own sandbox containers reaching each other) go via
      # host.docker.internal on ports Docker assigns randomly per-run — an
      # allowedTCPPorts entry can't keep up with that. Docker's bridge
      # already isolates containers from the real LAN, so this doesn't
      # expose anything new externally.
      trustedInterfaces = lib.mkIf config.my.isHighPower [ "docker0" ];
    };
  };

  environment.etc."systemd/system-sleep/disable-acpi-wakeup.sh" = lib.mkIf config.my.isHighPower {
    mode = "0755";
    text = ''
      #!/bin/sh
      case "$1" in
        pre)
          ${pkgs-stable.util-linux}/bin/logger -t disable-acpi-wakeup "running, args: $*"
          for dev in PTXH XHC0; do
            if ${pkgs-stable.gnugrep}/bin/grep -q "^$dev[[:space:]].*enabled" /proc/acpi/wakeup; then
              echo "$dev" > /proc/acpi/wakeup
              ${pkgs-stable.util-linux}/bin/logger -t disable-acpi-wakeup "toggled $dev off"
            else
              ${pkgs-stable.util-linux}/bin/logger -t disable-acpi-wakeup "$dev already disabled or not found"
            fi
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
