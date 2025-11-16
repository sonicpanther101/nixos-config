{ config, lib, pkgs-stable, inputs, ... }:

with lib;

let
  cfg = config.services.foobar2000-mpris;
  
  # Config file for beefweb_mpris
  configFile = pkgs-stable.writeText "beefweb-mpris-config.yaml" ''
    beefweb:
      host: ${cfg.beefwebHost}
      port: ${toString cfg.beefwebPort}
    
    foobar2000-command: ${cfg.foobar2000Package}/bin/foobar2000-${cfg.wineArch}
    
    mpris:
      identity: foobar2000
  '';

in {
  options.services.foobar2000-mpris = {
    enable = mkEnableOption "foobar2000 with MPRIS support";
    
    beefwebHost = mkOption {
      type = types.str;
      default = "localhost";
      description = "Beefweb server host";
    };
    
    beefwebPort = mkOption {
      type = types.int;
      default = 8880;
      description = "Beefweb server port";
    };
    
    wineArch = mkOption {
      type = types.enum [ "win32" "win64" ];
      default = "win64";
      description = "Wine architecture (win32 or win64)";
    };
    
    winePackage = mkOption {
      type = types.package;
      default = pkgs-stable.wine64Packages.unstable;
      description = "Wine package to use";
    };
    
    foobar2000Package = mkOption {
      type = types.package;
      default = null;
      description = "Custom foobar2000 package (leave null for default)";
    };
    
    autoStart = mkOption {
      type = types.bool;
      default = false;
      description = "Auto-start beefweb_mpris as a systemd user service";
    };
  };

  config = mkIf cfg.enable {
    # Ensure foobar2000Package is set
    services.foobar2000-mpris.foobar2000Package = mkDefault (
      inputs.erosanix.packages.${pkgs-stable.system}.foobar2000.override {
        wine = cfg.winePackage;
        wineArch = cfg.wineArch;
      }
    );

    environment.systemPackages = [
      cfg.foobar2000Package
      (pkgs-stable.callPackage ../../packages/beefweb_mpris.nix { })
      pkgs-stable.playerctl
    ];

    # Create config directory structure
    system.activationScripts.beefweb-mpris-config = ''
      mkdir -p /etc/xdg/beefweb_mpris
      ln -sf ${configFile} /etc/xdg/beefweb_mpris/config.yaml
    '';

    # Systemd user service (optional)
    systemd.user.services.beefweb-mpris = mkIf cfg.autoStart {
      description = "Beefweb MPRIS Bridge for foobar2000";
      after = [ "graphical-session.target" ];
      wantedBy = [ "default.target" ];
      
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs-stable.beefweb_mpris}/bin/beefweb_mpris";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      
      environment = {
        XDG_CONFIG_HOME = "%h/.config";
      };
    };
  };
}