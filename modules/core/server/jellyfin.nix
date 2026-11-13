# ─── Jellyfin ────────────────────────────────────────────────────────────
# Reachable at http://<lanIp>:8096/. Libraries are added in its web UI (STEP 10).
# Remote viewing goes over Tailscale (trusted interface), not the Cloudflare tunnel.
#
# STEP 10 — Jellyfin (after the rebuild):
#   Open http://<lanIp>:8096/, make the admin account, then add libraries:
#     Movies -> /srv/data/Movies   TV Shows -> /srv/data/TV   Music -> "/srv/data/Music/My Playlist"
#   Away from home, install Tailscale on the phone/TV/laptop and point the Jellyfin
#   app at http://<server's tailscale name or 100.x address>:8096. Video goes over
#   Tailscale, NOT the Cloudflare tunnel (Cloudflare restricts serving video on its CDN).
{ lib, config, ... }:
let
  inherit (import ./vars.nix) dataDir;
in {
  config = lib.mkIf config.my.isServer {
    services.jellyfin = {
      enable = true;
      openFirewall = true;    # 8096 (http), 8920 (https), 1900 + 7359 (LAN discovery)
      group = "users";        # primary group, so it can read the media in ${dataDir}
    };

    systemd.services.jellyfin.unitConfig.RequiresMountsFor = dataDir;
  };
}
