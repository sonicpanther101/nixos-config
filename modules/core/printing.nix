{ pkgs-stable, ... }: {
  services.printing = {
    enable = true;

    drivers = [ 
      pkgs-stable.gutenprint 
      pkgs-stable.cups-filters 
      pkgs-stable.foomatic-db
      pkgs-stable.foomatic-db-ppds
      pkgs-stable.foomatic-db-engine
    ];

    # Enable printer discovery
    browsing = true;
    defaultShared = false;
    
    # Allow remote administration
    listenAddresses = [ "localhost:631" ];
    allowFrom = [ "localhost" ];
    
  };

  # Enable Avahi for printer discovery on the network
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
