{ pkgs-stable, ... }: {
  services.printing = {
    enable = true;

    drivers = [ pkgs-stable.gutenprint pkgs-stable.cups-filters ];

    # Allow CUPS to discover printers on the network
    browsing = true;
    listenAddresses = [ "localhost:631" ];
    allowFrom = [ "all" ];
    defaultShared = false;
  };

  # Install required packages for printer management
  environment.systemPackages = with pkgs-stable; [
    system-config-printer  # GUI for managing printers
  ];

  # Enable Samba client support (needed for Windows printer servers)
  services.samba = {
    enable = true;
    package = pkgs-stable.samba;
  };
}