# ─── slskd (Soulseek) ────────────────────────────────────────────────────
# Reachable at http://<lanIp>:5030/. Logins come from ${secretsDir}/slskd.env (STEP 1).
{ lib, config, username, ... }:
let
  inherit (import ./vars.nix) dataDir secretsDir;
in {
  config = lib.mkIf config.my.isServer {
    services.slskd = {
      enable = true;
      domain = null;                                  # no nginx vhost for now
      openFirewall = true;                            # Soulseek listen port (50300)
      environmentFile = "${secretsDir}/slskd.env";    # Soulseek + web UI logins
      group = "users";                                # shared with you and nextcloud

      settings = {
        shares.directories = [ "${dataDir}/Music" ];
        directories = {
          downloads = "${dataDir}/slskd/downloads";
          incomplete = "${dataDir}/slskd/incomplete";
        };
        web.port = 5030;
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d ${dataDir}/slskd            0755 slskd       users -"
        "d ${dataDir}/slskd/downloads  0775 slskd       users -"
        "d ${dataDir}/slskd/incomplete 0775 slskd       users -"
      ];
      services.slskd = {
        unitConfig.RequiresMountsFor = dataDir;
        serviceConfig.UMask = "0002";   # downloads come out group-writable for nextcloud
      };
    };

    networking.firewall.allowedTCPPorts = [ 5030 ];   # web UI
  };
}
