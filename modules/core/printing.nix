{ pkgs-stable, ... }: {
  services.printing = {
    enable = true;

    drivers = [ pkgs-stable.gutenprint pkgs-stable.cups-filters ];

  };
}