# ─────────────────────────────────────────────────────────────────────────────
# SERVER SERVICES — Nextcloud, Radicale, the *arr suite + qBittorrent, Forgejo (+ GitHub mirrors),
# slskd (Soulseek), Kiwix and Jellyfin, disk health alerts (smartd -> phone push),
# plus remote access (Cloudflare Tunnel, Tailscale, headless Sunshine)
#
# Only active when `my.isServer = true` (see hosts/server/default.nix), so it is
# safe for every host to import it.
#
# Reachable on the local network at:
#   Nextcloud    http://<lanIp>/        (port 80; use https://cloud.<domain> once the tunnel is up)
#   Radicale     http://<lanIp>:5232/   (login required)
#   slskd        http://<lanIp>:5030/
#   Kiwix        http://<lanIp>:8080/
#   Jellyfin     http://<lanIp>:8096/   (from outside: over Tailscale, see STEP 10)
#   qBittorrent  http://<lanIp>:8081/
#   Prowlarr     http://<lanIp>:9696/
#   Sonarr       http://<lanIp>:8989/
#   Radarr       http://<lanIp>:7878/
#   Lidarr       http://<lanIp>:8686/
#   Shelfmark    http://<lanIp>:8084/   (books + audiobooks, searches through Prowlarr)
#   Forgejo      https://git.<domain> only (tunnel, see STEP 9)
#
# From outside the house everything goes through the Cloudflare Tunnel, and the
# remote desktop (Sunshine/Moonlight) goes through Tailscale. See the server
# setup guide for the domain, tunnel and Sunshine steps.
#
# All the media folders live directly in /srv/data and share group `users`, so
# the same files are visible to qBittorrent, the *arr apps, slskd, Nextcloud
# and you:  Downloads/  TV/  Movies/  Music/  Books/  slskd/  kiwix/
#
# ONE-TIME SETUP — do this on the server BEFORE the first rebuild. The steps that
# belong to a single service live at the top of that service's file:
#   STEP 4 kiwix.nix | 5 nextcloud.nix | 6 radicale.nix | 7, 8, 12 remote-access.nix
#   STEP 9, 13 forgejo.nix | 10 jellyfin.nix | 11 disk-health.nix | 14, 15 music-pipeline.nix
#   STEP 16 soularr.nix
#
# STEP 1 — Create the secrets directory and the files the services read:
#   sudo mkdir -p -m 700 /var/lib/server-secrets
#   echo 'choose-a-nextcloud-admin-password' | sudo tee /var/lib/server-secrets/nextcloud-admin-pass
#   sudo tee /var/lib/server-secrets/slskd.env <<'EOF'
#   SLSKD_SLSK_USERNAME=your-soulseek-username
#   SLSKD_SLSK_PASSWORD=your-soulseek-password
#   SLSKD_USERNAME=admin
#   SLSKD_PASSWORD=choose-a-web-ui-password
#   EOF
#   sudo chmod 600 /var/lib/server-secrets/*
#   (A Soulseek account is created just by logging in with a new name/password.)
#
# STEP 2 — Check lanIp in vars.nix matches this machine:
#   ip -4 addr show   (and give it a DHCP reservation in your router)
#
# STEP 3 — Rebuild:
#   my-install
#
# The cloudflared unit is skipped until its token file exists, so the first
# rebuild is safe without STEP 7.
# ─────────────────────────────────────────────────────────────────────────────
{ lib, config, username, ... }:
let
  inherit (import ./vars.nix) dataDir;
in {
  imports = [
    ./nextcloud.nix
    ./radicale.nix
    ./slskd.nix
    ./kiwix.nix
    ./jellyfin.nix
    ./arr.nix
    ./music-pipeline.nix
    ./soularr.nix
    ./forgejo.nix
    ./disk-health.nix
    ./remote-access.nix
  ];

  config = lib.mkIf config.my.isServer {

    # ─── Storage ─────────────────────────────────────────────────────────────
    # /home/<user> is private (0700), so system services can't read
    # ~/driveBig directly. Expose the same drive at /srv/data instead.
    # nofail + requires-mounts-for: if the drive is missing, the bind mount and
    # the services that need it are skipped instead of writing to the root disk.
    fileSystems.${dataDir} = {
      device = "/home/${username}/driveBig";
      fsType = "none";
      options = [
        "bind"
        "nofail"
        "x-systemd.requires-mounts-for=/home/${username}/driveBig"
      ];
    };

    # The shared media folders. Folders that belong to one service are created in
    # that service's file (kiwix, slskd, radicale, forgejo backups).
    systemd.tmpfiles.rules = [
      "d ${dataDir}/Music            2775 ${username} users -"
      "d ${dataDir}/PhoneMusic       2775 ${username} users -"
      "d ${dataDir}/Downloads        2775 ${username} users -"
      "d ${dataDir}/TV               2775 ${username} users -"
      "d ${dataDir}/Movies           2775 ${username} users -"
      "d ${dataDir}/Books            2775 ${username} users -"
      "d ${dataDir}/Photos           2775 ${username} users -"
      # Backups: owner-only, since dumps contain secrets
      "d ${dataDir}/backups          0700 ${username} users -"
    ];
  };
}
