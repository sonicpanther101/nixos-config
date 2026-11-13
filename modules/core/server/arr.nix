# ─── *arr suite + qBittorrent + Shelfmark ───────────────────────────────
# Prowlarr finds, Sonarr (TV) / Radarr (movies) / Lidarr (music) decide and
# qBittorrent downloads. Their web UIs are LAN-only by default (to reach one from
# outside, publish it in the Cloudflare dashboard like the other tunnel hostnames).
# Each asks you to create a login on first visit (Settings > General > Authentication):
# use long unique passwords.
#   Prowlarr http://<lanIp>:9696/   Sonarr http://<lanIp>:8989/   Radarr http://<lanIp>:7878/
#   Lidarr   http://<lanIp>:8686/   qBittorrent http://<lanIp>:8081/   Shelfmark http://<lanIp>:8084/
# All run in group `users`, the same group as you, slskd and Nextcloud, so
# they all read and write the same folders in ${dataDir}.
{ lib, config, pkgs-stable, ... }:
let
  inherit (import ./vars.nix) dataDir;

  qbConfigure = pkgs-stable.callPackage ../../../packages/server-scripts/qbittorrent-configure.nix {
    confPath = "${config.services.qbittorrent.profileDir}/qBittorrent/config/qBittorrent.conf";
  };
in {
  config = lib.mkIf config.my.isServer {
    services = {
      prowlarr = {
        enable = true;
        openFirewall = true;    # 9696
      };
      sonarr = {
        enable = true;
        group = "users";
        openFirewall = true;    # 8989
      };
      radarr = {
        enable = true;
        group = "users";
        openFirewall = true;    # 7878
      };
      lidarr = {
        enable = true;
        group = "users";
        openFirewall = true;    # 8686
      };
      qbittorrent = {
        enable = true;
        group = "users";
        webuiPort = 8081;       # 8080 is Kiwix
        torrentingPort = 6881;
        openFirewall = true;
        extraArgs = [ "--confirm-legal-notice" ];
        # serverConfig is deliberately left empty: setting it makes the module
        # overwrite qBittorrent.conf (and your web UI password) on every start.
        # The few settings the tunnel needs are pinned by qbConfigure instead.
      };
      flaresolverr = {
        enable = true;
        # openFirewall = false;   # default; Prowlarr reaches it via localhost
      };

      # Readarr is dead, so Shelfmark takes its place (books + audiobooks): it searches
      # through Prowlarr, hands torrents to qBittorrent and moves the finished files into
      # ${dataDir}/Books. Prowlarr / qBittorrent logins are entered in its web UI
      # (not here: anything in this file ends up readable in the nix store).
      shelfmark = {
        enable = true;
        openFirewall = true;    # 8084
        environment = {
          FLASK_HOST = "0.0.0.0";           # the module default is localhost only
          INGEST_DIR = "${dataDir}/Books";  # where finished books land
        };
      };
    };

    # 6881 UDP: torrent peers (the qbittorrent module only opens it for TCP)
    networking.firewall.allowedUDPPorts = [ 6881 ];

    systemd.services = lib.genAttrs [ "sonarr" "radarr" "lidarr" ] (_: {
      unitConfig.RequiresMountsFor = dataDir;
      # The modules default to 0022; 0002 keeps imported files group-writable for `users`
      serviceConfig.UMask = lib.mkForce "0002";
    }) // {
      qbittorrent = {
        unitConfig.RequiresMountsFor = dataDir;
        serviceConfig = {
          UMask = lib.mkForce "0002";
          ExecStartPre = "-${qbConfigure}";   # leading "-": a failure here never blocks the start
        };
      };
      shelfmark = {
        unitConfig.RequiresMountsFor = dataDir;
        serviceConfig = {
          # The module runs it as a throwaway user in a private user namespace, which
          # can't write to the shared folders. Join `users` like the *arr apps do.
          SupplementaryGroups = [ "users" ];
          ReadWritePaths = [ "${dataDir}/Books" ];
          UMask = lib.mkForce "0002";
          PrivateUsers = lib.mkForce false;
        };
      };
    };
  };
}
