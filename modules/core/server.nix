# ─────────────────────────────────────────────────────────────────────────────
# SERVER SERVICES — Nextcloud, slskd (Soulseek) and Kiwix
#
# Only active when `my.isServer = true` (see hosts/server/default.nix), so it is
# safe for every host to import it.
#
# Reachable on the local network at:
#   Nextcloud  http://<lanIp>/        (port 80)
#   slskd      http://<lanIp>:5030/
#   Kiwix      http://<lanIp>:8080/
#   (Radicale  http://<lanIp>:5232/   is configured in services.nix)
#
# ONE-TIME SETUP — do this on the server BEFORE the first rebuild:
#
#   STEP 1 — Create the secrets directory and the files the services read:
#     sudo mkdir -p -m 700 /var/lib/server-secrets
#     echo 'choose-a-nextcloud-admin-password' | sudo tee /var/lib/server-secrets/nextcloud-admin-pass
#     sudo tee /var/lib/server-secrets/slskd.env <<'EOF'
#     SLSKD_SLSK_USERNAME=your-soulseek-username
#     SLSKD_SLSK_PASSWORD=your-soulseek-password
#     SLSKD_USERNAME=admin
#     SLSKD_PASSWORD=choose-a-web-ui-password
#     EOF
#     sudo chmod 600 /var/lib/server-secrets/*
#     (A Soulseek account is created just by logging in with a new name/password.)
#
#   STEP 2 — Check lanIp below matches this machine:
#     ip -4 addr show   (and give it a DHCP reservation in your router)
#
#   STEP 3 — Rebuild:
#     my-install
#
#   STEP 4 — Kiwix serves every .zim file in /srv/data/kiwix and needs at least one.
#     Pick files from https://download.kiwix.org/zim/ then:
#       cd /srv/data/kiwix && curl -LO <zim-url>
#       sudo systemctl restart kiwix-serve   (the folder is re-scanned on every start)
#     (Until the folder has something in it the kiwix-serve unit is just skipped.)
#
#   STEP 5 — Give Nextcloud its folders (one-time, after the first rebuild):
#     sudo nextcloud-occ app:enable files_external
#     sudo nextcloud-occ files_external:create /Music local null::null -c datadir=/srv/data/Music
#     sudo nextcloud-occ files_external:create /Soulseek local null::null -c datadir=/srv/data/slskd/downloads
#     Repeat for any other folder (e.g. /Kobo -> /srv/data/Kobo). Don't mount all of
#     /srv/data: Nextcloud's own config/ and data/ folders live at its root.
#
# LATER — domain + port forwarding (see the commented block at the bottom).
# ─────────────────────────────────────────────────────────────────────────────
{ lib, config, pkgs-stable, username, ... }:
let
  # This machine's LAN address (same one weak-machine.nix uses to reach the server).
  lanIp = "10.194.64.27";

  # Bulk storage. This is a bind mount of ~/driveBig (see below), so the
  # services can reach it without needing access to your home directory.
  dataDir = "/srv/data";

  # Root-only files holding passwords. Never put these in the nix store.
  secretsDir = "/var/lib/server-secrets";

  # Kiwix: every .zim in ${dataDir}/kiwix is added to this library file each
  # time the service starts (runs as ExecStartPre, see systemd.services below).
  kiwixLibrary = "/var/lib/kiwix/library.xml";
  refreshKiwixLibrary = pkgs-stable.writeShellScript "kiwix-refresh-library" ''
    set -eu
    rm -f ${kiwixLibrary}
    for zim in ${dataDir}/kiwix/*.zim; do
      [ -e "$zim" ] || continue
      ${lib.getExe' config.services.kiwix-serve.package "kiwix-manage"} ${kiwixLibrary} add "$zim"
    done
  '';
in {
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

    systemd.tmpfiles.rules = [
      "d ${dataDir}/Music            0775 ${username} users -"
      "d ${dataDir}/kiwix            0755 ${username} users -"
      "d ${dataDir}/slskd            0755 slskd       users -"
      "d ${dataDir}/slskd/downloads  0775 slskd       users -"
      "d ${dataDir}/slskd/incomplete 0775 slskd       users -"
    ];

    services = {
      # ─── Nextcloud ───────────────────────────────────────────────────────────
      nextcloud = {
        enable = true;
        # Must be explicit: the default follows system.stateVersion (25.05),
        # which would pick the old nextcloud31 instead of 35.
        package = pkgs-stable.nextcloud34;

        hostName = lanIp;   # also added to trusted_domains automatically
        https = false;      # becomes true once there is a domain + TLS

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
          # trusted_domains = [ "cloud.example.com" ];   # add when you have a domain
        };

        datadir = "${dataDir}";

        # Data lives in /var/lib/nextcloud on the root disk. To put it on the big
        # drive instead, set `datadir = "${dataDir}";` before first setup.
      };

      # ─── slskd (Soulseek) ────────────────────────────────────────────────────
      slskd = {
        enable = true;
        domain = null;                                  # no nginx vhost for now
        openFirewall = true;                            # Soulseek listen port (50300)
        environmentFile = "${secretsDir}/slskd.env";    # Soulseek + web UI logins
        group = "users";                                # shared with adam and nextcloud

        settings = {
          shares.directories = [ "${dataDir}/Music" ];
          directories = {
            downloads = "${dataDir}/slskd/downloads";
            incomplete = "${dataDir}/slskd/incomplete";
          };
          web.port = 5030;
        };
      };

      # ─── Kiwix ───────────────────────────────────────────────────────────────
      kiwix-serve = {
        enable = true;
        port = 8080;
        openFirewall = true;
        libraryPath = kiwixLibrary;
      };
    };

    # Nextcloud (php-fpm runs as `nextcloud`) joins `users` so it can reach Music and
    # the Soulseek downloads, which are group-writable for that group.
    users.users.nextcloud.extraGroups = [ "users" ];

    # ─── Mount / file guards ─────────────────────────────────────────────────
    systemd.services = {
      slskd = {
        unitConfig.RequiresMountsFor = dataDir;
        serviceConfig.UMask = "0002";   # downloads come out group-writable for nextcloud
      };
      kiwix-serve = {
        unitConfig = {
          RequiresMountsFor = dataDir;
          # Skip quietly until the .zim files have actually been downloaded
          ConditionDirectoryNotEmpty = "${dataDir}/kiwix";
        };
        serviceConfig = {
          StateDirectory = "kiwix";            # writable home for library.xml
          ExecStartPre = refreshKiwixLibrary;  # rebuild it from the folder
        };
      };
    };

    # ─── Firewall ────────────────────────────────────────────────────────────
    # Nextcloud (nginx) and the slskd web UI; Kiwix and the Soulseek port are
    # opened by their own openFirewall options above. Syncthing's ports are added
    # here too: services.syncthing.openDefaultPorts in services.nix has no effect
    # because Syncthing runs through home-manager, not the NixOS module.
    networking.firewall = {
      allowedTCPPorts = [ 80 5030 22000 ];
      allowedUDPPorts = [ 22000 21027 ];
    };

    # ─── Domain + port forwarding (later) ────────────────────────────────────
    # 1. Point the domain's DNS at your public IP (or use a dynamic-DNS client).
    # 2. Router: forward TCP 80 and 443 to ${lanIp}, and TCP 50300 for Soulseek
    #    if you want incoming connections. Do NOT forward 5030 or 8080 (slskd
    #    UI / Kiwix); Kiwix has no login at all.
    # 3. Then change the Nextcloud block above to roughly:
    #      hostName = "cloud.example.com";
    #      https = true;
    #      settings.overwriteprotocol = "https";
    #      settings.trusted_domains = [ "${lanIp}" ];
    #    and add:
    #      services.nginx.virtualHosts."cloud.example.com" = {
    #        forceSSL = true;
    #        enableACME = true;
    #      };
    #      security.acme = { acceptTerms = true; defaults.email = "you@example.com"; };
    #      networking.firewall.allowedTCPPorts = [ 443 ];
    #    Note forceSSL redirects plain-http LAN visits to the domain too; reach
    #    it from inside the house via the domain (needs hairpin NAT or local DNS).
  };
}
