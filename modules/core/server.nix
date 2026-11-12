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
#     sudo nextcloud-occ files_external:create /Downloads local null::null -c datadir=/srv/data/Downloads
#     sudo nextcloud-occ files_external:create /TV local null::null -c datadir=/srv/data/TV
#     sudo nextcloud-occ files_external:create /Movies local null::null -c datadir=/srv/data/Movies
#     Repeat for any other folder (e.g. /Kobo -> /srv/data/Kobo). Don't mount all of
#     /srv/data: Nextcloud's own config/ and data/ folders live at its root.
#     (Optional, so changes made by qBittorrent/Sonarr show up straight away:
#      sudo nextcloud-occ files_external:list   then for each mount id:
#      sudo nextcloud-occ files_external:option <id> filesystem_check_changes 1)
#
#   STEP 6 — Radicale logins (an empty login file is created for you, so Radicale
#     starts but refuses everyone until you add yourself):
#     nix-shell -p apacheHttpd --run "htpasswd -B -c /tmp/radicale-users adam"
#     sudo mv /tmp/radicale-users /var/lib/radicale/users
#     sudo chown radicale:radicale /var/lib/radicale/users && sudo chmod 640 /var/lib/radicale/users
#     (Use -B without -c to add another user later. If you are migrating the old
#     desktop calendars, the user name must match the folder name inside
#     /var/lib/radicale/collections/collection-root/.)
#
#   STEP 7 — Cloudflare Tunnel token (from the Cloudflare dashboard, see the guide):
#     sudo tee /var/lib/server-secrets/cloudflared.env <<'EOF'
#     TUNNEL_TOKEN=paste-the-long-token-here
#     EOF
#     sudo chmod 600 /var/lib/server-secrets/cloudflared.env
#     sudo systemctl restart cloudflared
#
#   STEP 8 — Tailscale (remote desktop from other networks):
#     sudo tailscale up
#
#   STEP 9 — Forgejo (light git forge, about 200 MB of RAM; web UI only through the tunnel):
#     a. After the rebuild, create your admin account (registration is switched off):
#          sudo -u forgejo forgejo admin user create --admin --username adam \
#            --email you@example.com --random-password \
#            --config /var/lib/forgejo/custom/conf/app.ini --work-path /var/lib/forgejo
#        It prints the first password; change it in the web UI.
#     b. Cloudflare dashboard: Zero Trust > Networks > Tunnels > your tunnel > Published
#        application routes > add git.<domain> -> HTTP localhost:3000.
#     Clone over https with an access token (User settings > Applications). SSH is off.
#     Backups (nightly, 03:00): Forgejo dumps everything (repos, issues, users, settings)
#     to /var/lib/forgejo/dump (a week kept), then the dump is copied to
#     /srv/data/backups/forgejo on the big drive (30 days kept), and Syncthing sends that
#     folder to the desktop. Check it with:
#       systemctl list-timers forgejo-dump      sudo systemctl start forgejo-dump
#       journalctl -u forgejo-dump -u forgejo-dump-copy      ls -l /srv/data/backups/forgejo
#     Off-site copy of the git data: STEP 13 pushes every repo to GitHub.
#
#   STEP 10 — Jellyfin (after the rebuild):
#     Open http://<lanIp>:8096/, make the admin account, then add libraries:
#       Movies -> /srv/data/Movies   TV Shows -> /srv/data/TV   Music -> /srv/data/Music
#     Away from home, install Tailscale on the phone/TV/laptop and point the Jellyfin
#     app at http://<server's tailscale name or 100.x address>:8096. Video goes over
#     Tailscale, NOT the Cloudflare tunnel (Cloudflare restricts serving video on its CDN).
#
#   STEP 11 — Disk health alerts (smartd pushes to your phone through ntfy.sh):
#     sudo tee /var/lib/server-secrets/ntfy.env <<EOF
#     NTFY_TOPIC=server-disks-$(openssl rand -hex 12)
#     EOF
#     sudo chmod 600 /var/lib/server-secrets/ntfy.env
#     sudo cat /var/lib/server-secrets/ntfy.env
#     Install the ntfy app on your phone and subscribe to that exact topic name (the
#     topic is the only secret, so don't share it). Then send yourself a test:
#       sudo smartd-ntfy
#     List what smartd is watching with:  sudo smartctl --scan   and   journalctl -u smartd
#     (A drive in a USB enclosure may need `-d sat`: see the smartd note below.)
#
#   STEP 12 — Syncthing's web UI through the tunnel (Cloudflare dashboard, no rebuild):
#     a. FIRST protect it: Zero Trust > Access > Applications > Add > Self-hosted for
#        syncthing.<domain>, with a policy that allows only your email.
#     b. Then publish it: Zero Trust > Networks > Tunnels > your tunnel > Published
#        application routes > add syncthing.<domain> -> HTTP localhost:8384, and under
#        Additional application settings > HTTP Settings set "HTTP Host Header" to
#        localhost (Syncthing rejects Host headers it doesn't know).
#     c. In Syncthing: Actions > Settings > GUI, set a GUI user and password as well.
#     Only the web UI goes through the tunnel. Syncing itself (port 22000) can't: it
#     already works over the LAN, Tailscale and Syncthing's own relays.
#
#   STEP 13 — Forgejo repos mirrored to GitHub (forgesync, an off-site copy of the git data):
#     Forgesync creates a GitHub repo with the same name for each of your Forgejo repos
#     and sets up a push mirror in Forgejo. Private repos stay private. It OVERWRITES any
#     GitHub repo that already has the same name as one of yours, so check for clashes
#     first. Forks and mirrors are skipped. Wikis and issues are not mirrored (the dumps
#     in STEP 9 have those).
#     a. Forgejo: User settings > Applications > new token with write:repository and
#        read:user. This is SOURCE_TOKEN.
#     b. GitHub: Settings > Developer settings > Personal access tokens > Fine-grained
#        tokens. Make two, both with "All repositories" (the repos don't exist yet):
#          TARGET_TOKEN: Administration read+write, Contents read-only, Metadata read-only
#          MIRROR_TOKEN: Contents read+write, Metadata read-only
#     c. Put them on the server:
#          sudo tee /var/lib/server-secrets/forgesync.env <<'EOF'
#          SOURCE_TOKEN=paste-forgejo-token
#          TARGET_TOKEN=paste-github-token-1
#          MIRROR_TOKEN=paste-github-token-2
#          EOF
#          sudo chmod 600 /var/lib/server-secrets/forgesync.env
#     d. Dry run first (prints what it would do, changes nothing):
#          sudo bash -c 'set -a; . /var/lib/server-secrets/forgesync.env; set +a; \
#            nix run github:lukaswrz/forgesync -- --dry-run --include-private \
#            http://127.0.0.1:3000/api/v1 github'
#     e. Then run it for real, and again any time (it also runs daily on its own):
#          sudo systemctl start forgesync-job-github
#          journalctl -u forgesync-job-github -n 50
#        Afterwards each repo in Forgejo has a push mirror (repo > Settings > Repository >
#        Mirror settings) that pushes to GitHub on every commit and every 8 hours.
#     The mirror token is stored inside Forgejo, so it is also in the STEP 9 dumps.
#
# The cloudflared unit is skipped until its token file exists, so the first
# rebuild is safe without STEP 7.
# ─────────────────────────────────────────────────────────────────────────────
{ lib, config, pkgs-stable, username, inputs, ... }:
let
  # This machine's LAN address
  lanIp = "192.168.1.247";

  # Bulk storage. This is a bind mount of ~/driveBig (see below), so the
  # services can reach it without needing access to your home directory.
  dataDir = "/srv/data";

  # Root-only files holding passwords. Never put these in the nix store.
  secretsDir = "/var/lib/server-secrets";

  # Your Cloudflare domain. Nextcloud gets cloud.<domain>; every other
  # hostname (dav, sonarr, ...) is added in the Cloudflare dashboard.
  domain = "adambeattie.dev";
  cloudHost = "cloud.${domain}";

  # Forgejo is a light git forge, only reachable through the tunnel (STEP 9)
  gitHost = "git.${domain}";

  # Second copy of the nightly Forgejo dump, on the big drive (a different disk from
  # /var/lib/forgejo). Owned by you and closed to everyone else, because a dump holds
  # Forgejo's secrets and password hashes. Syncthing sends this folder to the desktop.
  forgejoBackupDir = "${dataDir}/backups/forgejo";
  copyForgejoDump = pkgs-stable.writeShellScript "forgejo-dump-copy" ''
    set -eu
    # No --delete: this folder keeps more history than the 1 week Forgejo keeps itself
    ${pkgs-stable.rsync}/bin/rsync -a --chown=${username}:users --chmod=F600 \
      ${config.services.forgejo.dump.backupDir}/ ${forgejoBackupDir}/
    # Keep 30 days
    ${pkgs-stable.findutils}/bin/find ${forgejoBackupDir} -maxdepth 1 -type f -mtime +30 -delete
  '';

  # qBittorrent rewrites its own config, so instead of owning the whole file
  # (which would wipe your web UI password) this only pins the few settings
  # needed to sit safely behind the tunnel, before every start.
  qbConf = "${config.services.qbittorrent.profileDir}/qBittorrent/config/qBittorrent.conf";
  qbConfigure = pkgs-stable.writeShellScript "qbittorrent-configure" ''
    set -eu
    mkdir -p "$(dirname ${qbConf})"
    set_pref() {
      ${pkgs-stable.crudini}/bin/crudini --ini-options=nospace --set ${qbConf} Preferences "$1" "$2"
    }
    set_pref 'WebUI\HostHeaderValidation' false      # accept the public hostname
    set_pref 'WebUI\LocalHostAuth' true              # cloudflared connects from localhost: never skip the login
    set_pref 'WebUI\ReverseProxySupportEnabled' true # use the real visitor IP for login bans
    set_pref 'WebUI\TrustedReverseProxiesList' 127.0.0.1
  '';

  # smartd runs this as root when a drive reports a problem, with the details in
  # SMARTD_* variables. It sends a phone push through ntfy.sh to the topic in
  # ${secretsDir}/ntfy.env (STEP 11). It is also installed as `smartd-ntfy` so
  # `sudo smartd-ntfy` sends a test message. It always exits 0.
  smartdNotify = pkgs-stable.writeShellScriptBin "smartd-ntfy" ''
    set -u
    log() { ${pkgs-stable.util-linux}/bin/logger -t smartd-ntfy "$*"; }
    [ -r ${secretsDir}/ntfy.env ] && . ${secretsDir}/ntfy.env
    subject="''${SMARTD_SUBJECT:-Test message from smartd-ntfy}"
    log "$subject"
    if [ -z "''${NTFY_TOPIC:-}" ]; then
      log "no NTFY_TOPIC in ${secretsDir}/ntfy.env: push skipped"
      exit 0
    fi
    ${pkgs-stable.curl}/bin/curl -fsS --max-time 20 \
      -H "Title: $subject" \
      -H "Priority: urgent" \
      -H "Tags: warning,floppy_disk" \
      -d "''${SMARTD_FULLMESSAGE:-This is a test. If you can read it, disk alerts reach you.}" \
      "https://ntfy.sh/$NTFY_TOPIC" >/dev/null || log "ntfy push failed"
    exit 0
  '';

  # The video output the Hyprland/Sunshine session draws on. Check yours with:
  #   for f in /sys/class/drm/*/status; do echo "$f: $(cat $f)"; done
  headlessConnector = "HDMI-A-1";

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
  imports = [ inputs.forgesync.nixosModules.default ];
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
      "d ${dataDir}/Music            2775 ${username} users -"
      "d ${dataDir}/Downloads        2775 ${username} users -"
      "d ${dataDir}/TV               2775 ${username} users -"
      "d ${dataDir}/Movies           2775 ${username} users -"
      "d ${dataDir}/Books            2775 ${username} users -"
      "d ${dataDir}/Photos           2775 ${username} users -"
      "d ${dataDir}/kiwix            0755 ${username} users -"
      "d ${dataDir}/slskd            0755 slskd       users -"
      "d ${dataDir}/slskd/downloads  0775 slskd       users -"
      "d ${dataDir}/slskd/incomplete 0775 slskd       users -"
      # Backups: owner-only, since dumps contain secrets
      "d ${dataDir}/backups          0700 ${username} users -"
      "d ${forgejoBackupDir}         0700 ${username} users -"
      # Calendar server: the logins file must exist or Radicale refuses to start.
      # `f` only creates it when missing, so your real logins are never touched.
      "d /var/lib/radicale           0750 radicale radicale -"
      "d /var/lib/radicale/collections 0750 radicale radicale -"
      "f /var/lib/radicale/users     0640 radicale radicale -"
    ];

    services = {
      # ─── Nextcloud ───────────────────────────────────────────────────────────
      nextcloud = {
        enable = true;
        # Must be explicit: the default follows system.stateVersion (25.05),
        # which would pick the old nextcloud31 instead of 35.
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

      # ─── Jellyfin ────────────────────────────────────────────────────────────
      # Libraries are added in its web UI (STEP 10). Remote viewing goes over
      # Tailscale (trusted interface), not the Cloudflare tunnel.
      jellyfin = {
        enable = true;
        openFirewall = true;    # 8096 (http), 8920 (https), 1900 + 7359 (LAN discovery)
        group = "users";        # primary group, so it can read the media in ${dataDir}
      };

      # ─── Radicale (calendars + tasks) ────────────────────────────────────────
      # Moved here from services.nix. Logins live in /var/lib/radicale/users (STEP 6).
      radicale = {
        enable = true;
        settings = {
          server.hosts = [ "0.0.0.0:5232" ];
          auth = {
            type = "htpasswd";
            htpasswd_filename = "/var/lib/radicale/users";
            htpasswd_encryption = "bcrypt";
          };
        };
      };

      # ─── *arr suite ──────────────────────────────────────────────────────────
      # Prowlarr finds, Sonarr (TV) / Radarr (movies) / Lidarr (music) decide and
      # qBittorrent downloads. Their web UIs are LAN-only here; the tunnel exposes
      # them through the tunnel. Each asks you to create a login on first visit
      # (Settings > General > Authentication): use long unique passwords.
      # All run in group `users`, the same group as you, slskd and Nextcloud, so
      # they all read and write the same folders in ${dataDir}.
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

      # ─── Shelfmark (books + audiobooks) ──────────────────────────────────────
      # Readarr is dead, so this takes its place: it searches through Prowlarr,
      # hands torrents to qBittorrent and moves the finished files into
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

      # ─── Sunshine web UI through the tunnel ──────────────────────────────────
      # Sunshine itself is enabled in services.nix. Its web UI refuses requests
      # from any origin not listed here (CSRF error). Setting any option here
      # makes sunshine.conf read-only, so the web UI's Configuration tab can no
      # longer save changes: edit this list instead. Pairing and logins still work.
      sunshine.settings.csrf_allowed_origins = "https://sunshine.${domain},https://${lanIp}:47990,https://127.0.0.1:47990";

      # ─── Forgejo (git forge) ─────────────────────────────────────────────────
      # Listens on localhost only: the tunnel reaches it at git.<domain>. Uses a
      # SQLite database, so it does not touch Nextcloud's PostgreSQL.
      forgejo = {
        enable = true;
        dump = {
          enable = true;
          interval = "03:00";   # nightly
          age = "1w";           # keep a week
        };
        settings = {
          server = {
            DOMAIN = gitHost;
            ROOT_URL = "https://${gitHost}/";
            HTTP_ADDR = "127.0.0.1";
            DISABLE_SSH = true;     # the tunnel only carries http
          };
          service.DISABLE_REGISTRATION = true;
          session.COOKIE_SECURE = true;
        };
      };

      # ─── Forgesync (Forgejo -> GitHub push mirrors, STEP 13) ─────────────────
      # Runs daily and creates any missing GitHub repos and push mirrors. Talks to
      # Forgejo on localhost rather than through the tunnel. Forgejo itself then
      # pushes to GitHub on every commit (on-commit) and at least every 8 hours.
      forgesync = {
        enable = true;
        jobs.github = {
          source = "http://127.0.0.1:3000/api/v1";
          target = "github";
          secretFile = "${secretsDir}/forgesync.env";   # SOURCE_TOKEN, TARGET_TOKEN, MIRROR_TOKEN
          settings = {
            include-private = true;    # a backup should cover private repos too (they stay private)
            on-commit = true;
            mirror-interval = "8h0m0s";
          };
        };
      };

      # ─── Disk health (smartd) ────────────────────────────────────────────────
      # Watches every drive it can find (autodetect). When one reports a problem
      # smartd runs smartdNotify, which pushes to your phone (STEP 11), and
      # repeats the alert daily until it is fixed. The module's own wall/mail
      # notifiers are off so only one `-M exec` ends up in smartd.conf.
      #   -a                 health, attributes, error log and self-test log
      #   -o on              automatic offline data collection
      #   -s (S/...|L/...)   short self-test daily 02:00, long self-test Sundays 04:00
      #   -m <nomailer>      no email, just run the script
      # A drive behind a USB enclosure may need `-d sat`: set autodetect = false and
      # list it under `devices = [ { device = "/dev/sdX"; options = "-d sat"; } ];`
      smartd = {
        enable = true;
        notifications = {
          wall.enable = false;
          mail.enable = false;
          x11.enable = false;
        };
        defaults.monitored = "-a -o on -s (S/../.././02|L/../../7/04) -m <nomailer> -M exec ${lib.getExe smartdNotify}";
      };
    };

    users.users = {
      # Nextcloud (php-fpm runs as `nextcloud`) joins `users` so it can reach Music, the
      # downloads and the TV/Movies folders, which are group-writable for that group.
      nextcloud.extraGroups = [ "users" ];
    };

    # ─── Mount / file guards ─────────────────────────────────────────────────
    systemd.services = {
      slskd = {
        unitConfig.RequiresMountsFor = dataDir;
        serviceConfig.UMask = "0002";   # downloads come out group-writable for nextcloud
      };
      jellyfin.unitConfig.RequiresMountsFor = dataDir;
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
      
      # Cloudflare Tunnel: a "remotely managed" tunnel, so the hostname -> port
      # mapping is edited in the Cloudflare dashboard, not here. Skipped quietly
      # until the token file exists (STEP 7).
      cloudflared = {
        description = "Cloudflare Tunnel";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        unitConfig.ConditionPathExists = "${secretsDir}/cloudflared.env";
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs-stable.cloudflared} tunnel --no-autoupdate run";
          EnvironmentFile = "${secretsDir}/cloudflared.env";   # holds TUNNEL_TOKEN=...
          DynamicUser = true;
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
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
      # Forgejo backup: the module's nightly dump stays on /var/lib/forgejo, so as soon
      # as a dump succeeds, copy it to the big drive. A failed dump copies nothing.
      forgejo-dump.onSuccess = [ "forgejo-dump-copy.service" ];
      forgejo-dump-copy = {
        description = "Copy the Forgejo dump to the big drive";
        unitConfig.RequiresMountsFor = dataDir;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = copyForgejoDump;
        };
      };
      # Forgesync: wait for Forgejo and the network, and skip quietly until the token
      # file exists (STEP 13), so the first rebuild is safe without it.
      forgesync-job-github = {
        after = [ "forgejo.service" "network-online.target" ];
        wants = [ "network-online.target" ];
        unitConfig.ConditionPathExists = "${secretsDir}/forgesync.env";
      };
    } // lib.genAttrs [ "sonarr" "radarr" "lidarr" ] (_: {
      unitConfig.RequiresMountsFor = dataDir;
      # The modules default to 0022; 0002 keeps imported files group-writable for `users`
      serviceConfig.UMask = lib.mkForce "0002";
    });

    # smartctl for checking drives by hand, the `smartd-ntfy` test command, and
    # the `forgejo` command for admin tasks (STEP 9)
    environment.systemPackages = [ pkgs-stable.smartmontools smartdNotify config.services.forgejo.package ];

    # ─── Firewall ────────────────────────────────────────────────────────────
    # Nextcloud (nginx), the slskd web UI and Radicale; Kiwix, the *arr apps,
    # qBittorrent and the Soulseek port are opened by their own openFirewall
    # options above. Syncthing's ports are added here too:
    # services.syncthing.openDefaultPorts in services.nix has no effect because
    # Syncthing runs through home-manager, not the NixOS module.
    # Everything arriving over Tailscale is trusted (it only carries your own devices).
    networking.firewall = {
      allowedTCPPorts = [ 80 5030 5232 22000 ];
      allowedUDPPorts = [ 22000 21027 6881 ];   # 6881: torrent peers (the module only opens it for TCP)
      trustedInterfaces = [ "tailscale0" ];
    };

    # ─── Headless remote desktop ─────────────────────────────────────────────
    # Sunshine itself is enabled for every high-power host in services.nix. With
    # no monitor attached the GPU reports "nothing connected" and there is
    # nothing to capture, so force the connector on at 1080p. A real monitor
    # plugged in later still works (it just runs at 1080p60). A cheap HDMI
    # "dummy plug" does the same job in hardware if this is not enough.
    boot.kernelParams = [ "video=${headlessConnector}:1920x1080@60e" ];

  };
}
