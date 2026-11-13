# ─── Nextcloud ───────────────────────────────────────────────────────────
# Reachable at http://<lanIp>/ (port 80) and, once the tunnel is up, https://cloud.<domain>
#
# STEP 5 — Give Nextcloud its folders (one-time, after the first rebuild):
#   sudo nextcloud-occ app:enable files_external
#   sudo nextcloud-occ files_external:create /Music local null::null -c datadir=/srv/data/Music
#   sudo nextcloud-occ files_external:create /Soulseek local null::null -c datadir=/srv/data/slskd/downloads
#   sudo nextcloud-occ files_external:create /Downloads local null::null -c datadir=/srv/data/Downloads
#   sudo nextcloud-occ files_external:create /TV local null::null -c datadir=/srv/data/TV
#   sudo nextcloud-occ files_external:create /Movies local null::null -c datadir=/srv/data/Movies
#   Repeat for any other folder (e.g. /Kobo -> /srv/data/Kobo). Don't mount all of
#   /srv/data: Nextcloud's own config/ and data/ folders live at its root.
#   (Optional, so changes made by qBittorrent/Sonarr show up straight away:
#    sudo nextcloud-occ files_external:list   then for each mount id:
#    sudo nextcloud-occ files_external:option <id> filesystem_check_changes 1)
{ lib, config, pkgs-stable, ... }:
let
  inherit (import ./vars.nix) lanIp dataDir secretsDir domain;
  cloudHost = "cloud.${domain}";
in {
  config = lib.mkIf config.my.isServer {
    services.nextcloud = {
      enable = true;
      # Must be explicit: the default follows system.stateVersion (25.05),
      # which would pick the old nextcloud31 instead of the version pinned here.
      package = pkgs-stable.nextcloud34;

      hostName = cloudHost;   # also added to trusted_domains automatically
      https = true;           # Cloudflare handles TLS, the tunnel delivers plain http to nginx

      configureRedis = true;
      maxUploadSize = "16G";
      database.createLocally = true;

      config = {
        dbtype = "pgsql";
        adminuser = "admin";
        adminpassFile = "${secretsDir}/nextcloud-admin-pass";
      };

      settings = {
        default_phone_region = "NZ";
        files_external_allow_create_new_local = true;  # lets the admin UI add local folders too
        overwriteprotocol = "https";                   # links must be https even though the tunnel speaks http
        trusted_domains = [ lanIp ];                   # the domain is added automatically (hostName)
        trusted_proxies = [ "127.0.0.1" "::1" ];       # cloudflared connects from this machine
      };

      datadir = dataDir;
    };

    # Nextcloud (php-fpm runs as `nextcloud`) joins `users` so it can reach Music, the
    # downloads and the TV/Movies folders, which are group-writable for that group.
    users.users.nextcloud.extraGroups = [ "users" ];

    networking.firewall.allowedTCPPorts = [ 80 ];   # nginx
  };
}
