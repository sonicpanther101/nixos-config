# ─────────────────────────────────────────────────────────────────────────────
# SERVER SERVICES — Nextcloud, Radicale, the *arr suite + qBittorrent, GitLab,
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
#   Readarr      http://<lanIp>:8787/
#   GitLab       https://gitlab.<domain> only (tunnel; off until STEP 9)
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
#   STEP 9 — GitLab (heavy: wants 4 GB+ RAM free). Three parts, in this order:
#     9a. Back up Nextcloud's database while it still runs on PostgreSQL 16:
#           sudo nextcloud-occ maintenance:mode --on
#           sudo -u postgres pg_dump -Fc nextcloud > ~/nextcloud-db.dump
#     9b. Create GitLab's secrets. Run as one block:
#       sudo bash <<'EOF'
#       install -d -m 700 -o root -g root /var/lib/gitlab-secrets
#       cd /var/lib/gitlab-secrets
#       for f in secret otp db db-password activerecord-primary activerecord-deterministic activerecord-salt; do
#         openssl rand -hex 64 > $f
#       done
#       openssl genrsa 2048 > jws
#       openssl rand -base64 18 > root-password
#       chmod 600 *
#       cat root-password
#       EOF
#     (The last line prints the first root login; change it in the GitLab UI.
#      The rebuild hands the files to the gitlab user.)
#     9c. Set enableGitlab = true below and rebuild. That also moves the database
#         to PostgreSQL 17 (a fresh, empty cluster), so load Nextcloud's data back:
#           sudo systemctl stop phpfpm-nextcloud
#           sudo -u postgres pg_restore -d nextcloud --clean --if-exists -O --role=nextcloud ~/nextcloud-db.dump
#           sudo systemctl restart nextcloud-setup phpfpm-nextcloud
#           sudo nextcloud-occ maintenance:mode --off
#         (Messages about Nextcloud failing during that one rebuild are expected.)
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
# The cloudflared unit is skipped until its token file exists, so the first
# rebuild is safe without STEP 7.
# ─────────────────────────────────────────────────────────────────────────────
{ lib, config, pkgs-stable, username, ... }:
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

  # GitLab is heavy and needs its secrets first (STEP 9): flip this to true
  # once they exist.
  enableGitlab = false;
  gitlabHost = "gitlab.${domain}";
  gitlabSecrets = "/var/lib/gitlab-secrets";
  gitlabBackupDir = "${dataDir}/GitLab-backups";

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
      "d ${dataDir}/kiwix            0755 ${username} users -"
      "d ${dataDir}/slskd            0755 slskd       users -"
      "d ${dataDir}/slskd/downloads  0775 slskd       users -"
      "d ${dataDir}/slskd/incomplete 0775 slskd       users -"
      # Calendar server: the logins file must exist or Radicale refuses to start.
      # `f` only creates it when missing, so your real logins are never touched.
      "d /var/lib/radicale           0750 radicale radicale -"
      "d /var/lib/radicale/collections 0750 radicale radicale -"
      "f /var/lib/radicale/users     0640 radicale radicale -"
    ] ++ lib.optionals enableGitlab [
      # GitLab reads its secrets as the gitlab user: hand STEP 9's files over to it
      "d ${gitlabSecrets}            0700 gitlab gitlab -"
      "Z ${gitlabSecrets}            -    gitlab gitlab -"
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
      # Prowlarr finds, Sonarr (TV) / Radarr (movies) / Lidarr (music) / Readarr (books) decide and
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
      # Readarr is retired upstream (no more releases) but is still packaged in
      # nixpkgs. Its default metadata server no longer works, so it needs a
      # community mirror: see the Readarr setup notes.
      readarr = {
        enable = true;
        group = "users";
        openFirewall = true;    # 8787
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

      # ─── GitLab (off until STEP 9) ───────────────────────────────────────────
      # Behind the tunnel at gitlab.<domain>; GitLab has its own login (turn off
      # public sign-ups in its admin settings). Backed up nightly; mirror the
      # important projects to GitHub with push mirrors in the GitLab UI.
      gitlab = lib.mkIf enableGitlab {
        enable = true;
        host = gitlabHost;
        port = 443;   # only used for the URLs GitLab prints; Cloudflare serves the https
        https = true;
        databasePasswordFile = "${gitlabSecrets}/db-password";
        initialRootPasswordFile = "${gitlabSecrets}/root-password";
        secrets = {
          secretFile = "${gitlabSecrets}/secret";
          otpFile = "${gitlabSecrets}/otp";
          dbFile = "${gitlabSecrets}/db";
          jwsFile = "${gitlabSecrets}/jws";
          activeRecordPrimaryKeyFile = "${gitlabSecrets}/activerecord-primary";
          activeRecordDeterministicKeyFile = "${gitlabSecrets}/activerecord-deterministic";
          activeRecordSaltFile = "${gitlabSecrets}/activerecord-salt";
        };
        backup = {
          startAt = "03:00";   # nightly: at most a day of work lost
          path = gitlabBackupDir;
          keepTime = 7 * 24;   # hours: keep a week of backups
        };
      };

      # GitLab 19 needs PostgreSQL 17+, but with stateVersion 25.05 the shared
      # database (Nextcloud's too) is still PostgreSQL 16. Switching is a one-time
      # dump + restore, see STEP 9: do it BEFORE flipping enableGitlab.
      postgresql.package = lib.mkIf enableGitlab pkgs-stable.postgresql_17;

      # GitLab only speaks to a local socket; nginx hands it the tunnel's traffic.
      nginx.virtualHosts.${gitlabHost} = lib.mkIf enableGitlab {
        extraConfig = "client_max_body_size 1g;";   # big pushes
        locations."/" = {
          proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Proto https;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          '';
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
      # nginx must be able to open GitLab's socket
      nginx.extraGroups = lib.mkIf enableGitlab [ "gitlab" ];
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
    } // lib.genAttrs [ "sonarr" "radarr" "lidarr" "readarr" ] (_: {
      unitConfig.RequiresMountsFor = dataDir;
      # The modules default to 0022; 0002 keeps imported files group-writable for `users`
      serviceConfig.UMask = lib.mkForce "0002";
    });

    # smartctl for checking drives by hand, and the `smartd-ntfy` test command
    environment.systemPackages = [ pkgs-stable.smartmontools smartdNotify ];

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
