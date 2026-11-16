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
# Music quality (FLAC first, MP3 if there is no FLAC, upgraded later) is set in Lidarr's
# web UI, see STEP 16 in soularr.nix; lidarr-search below re-runs the searches daily.
{ lib, config, pkgs-stable, ... }:
let
  inherit (import ./vars.nix) dataDir;

  qbConfigure = pkgs-stable.callPackage ../../../packages/server-scripts/qbittorrent-configure.nix {
    confPath = "${config.services.qbittorrent.profileDir}/qBittorrent/config/qBittorrent.conf";
  };

  # Lidarr only searches the indexers when an album is added, when you press Search, and for
  # releases that appear in their RSS feeds afterwards. It never goes back over the wanted
  # list on its own, so an album the indexers didn't have yesterday stays missing for good.
  # Once a day this asks it to search Wanted > Missing, then Wanted > Cutoff Unmet (an MP3
  # that could be a FLAC), the albums searched longest ago first. 25 albums at a time with a
  # pause, so the indexers behind Prowlarr aren't hammered. Which quality gets grabbed is
  # the quality profile's job (FLAC preferred, MP3 allowed, upgrades allowed).
  maxPerList = 200;
  lidarrSearch = pkgs-stable.writeShellScript "lidarr-search" ''
    set -eu
    export PATH=${lib.makeBinPath (with pkgs-stable; [ curl jq gnused gnugrep findutils coreutils ])}
    key=$(sed -n 's:.*<ApiKey>\(.*\)</ApiKey>.*:\1:p' ${config.services.lidarr.dataDir}/config.xml)
    if [ -z "$key" ]; then
      echo "couldn't read Lidarr's API key (has Lidarr started once?)" >&2
      exit 1
    fi
    api=http://127.0.0.1:8686/api/v1
    for list in missing cutoff; do
      ids=$(curl -fsS -H "X-Api-Key: $key" "$api/wanted/$list?page=1&pageSize=1000&monitored=true" \
        | jq -r '[.records[] | select(.monitored)] | sort_by(.lastSearchTime // "") | .[:${toString maxPerList}] | .[].id')
      echo "$list: searching $(echo "$ids" | grep -c . || true) album(s)"
      echo "$ids" | xargs -r -n 25 | while read -r batch; do
        body=$(echo "$batch" | tr ' ' '\n' | jq -Rn '{name: "AlbumSearch", albumIds: [inputs | tonumber]}')
        curl -fsS -X POST -H "X-Api-Key: $key" -H "Content-Type: application/json" \
          -d "$body" "$api/command" > /dev/null
        sleep 120
      done
    done
  '';
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
      lidarr-search = {
        description = "Ask Lidarr to search its wanted albums on the Prowlarr indexers";
        startAt = "*-*-* 04:30:00";
        after = [ "lidarr.service" ];
        serviceConfig = {
          Type = "oneshot";
          User = config.services.lidarr.user;   # same user as Lidarr: it reads Lidarr's config.xml
          Nice = 10;
          TimeoutStartSec = "3h";   # 2 x 200 albums, a 2 minute pause per 25
          ExecStart = lidarrSearch;
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
