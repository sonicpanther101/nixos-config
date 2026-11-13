# ─── Forgejo (git forge) + Forgesync (GitHub push mirrors) ───────────────
# Listens on localhost only: the tunnel reaches it at git.<domain>. Uses a
# SQLite database, so it does not touch Nextcloud's PostgreSQL.
#
# STEP 9 — Forgejo (light git forge, about 200 MB of RAM; web UI only through the tunnel):
#   a. After the rebuild, create your admin account (registration is switched off):
#        sudo -u forgejo forgejo admin user create --admin --username adam \
#          --email you@example.com --random-password \
#          --config /var/lib/forgejo/custom/conf/app.ini --work-path /var/lib/forgejo
#      It prints the first password; change it in the web UI.
#   b. Cloudflare dashboard: Zero Trust > Networks > Tunnels > your tunnel > Published
#      application routes > add git.<domain> -> HTTP localhost:3000.
#   Clone over https with an access token (User settings > Applications). SSH is off.
#   Backups (nightly, 03:00): Forgejo dumps everything (repos, issues, users, settings)
#   to /var/lib/forgejo/dump (a week kept), then the dump is copied to
#   /srv/data/backups/forgejo on the big drive (30 days kept), and Syncthing sends that
#   folder to the desktop. Check it with:
#     systemctl list-timers forgejo-dump      sudo systemctl start forgejo-dump
#     journalctl -u forgejo-dump -u forgejo-dump-copy      ls -l /srv/data/backups/forgejo
#   Off-site copy of the git data: STEP 13 pushes every repo to GitHub.
#
# STEP 13 — Forgejo repos mirrored to GitHub (forgesync, an off-site copy of the git data):
#   Forgesync creates a GitHub repo with the same name for each of your Forgejo repos
#   and sets up a push mirror in Forgejo. Private repos stay private. It OVERWRITES any
#   GitHub repo that already has the same name as one of yours, so check for clashes
#   first. Forks and mirrors are skipped. Wikis and issues are not mirrored (the dumps
#   in STEP 9 have those).
#   a. Forgejo: User settings > Applications > new token with write:repository and
#      read:user. This is SOURCE_TOKEN.
#   b. GitHub: Settings > Developer settings > Personal access tokens > Fine-grained
#      tokens. Make two, both with "All repositories" (the repos don't exist yet):
#        TARGET_TOKEN: Administration read+write, Contents read-only, Metadata read-only
#        MIRROR_TOKEN: Contents read+write, Metadata read-only
#   c. Put them on the server:
#        sudo tee /var/lib/server-secrets/forgesync.env <<'EOF'
#        SOURCE_TOKEN=paste-forgejo-token
#        TARGET_TOKEN=paste-github-token-1
#        MIRROR_TOKEN=paste-github-token-2
#        EOF
#        sudo chmod 600 /var/lib/server-secrets/forgesync.env
#   d. Dry run first (prints what it would do, changes nothing):
#        sudo bash -c 'set -a; . /var/lib/server-secrets/forgesync.env; set +a; \
#          nix run github:lukaswrz/forgesync -- --dry-run --include-private \
#          http://127.0.0.1:3000/api/v1 github'
#   e. Then run it for real, and again any time (it also runs daily on its own):
#        sudo systemctl start forgesync-job-github
#        journalctl -u forgesync-job-github -n 50
#      Afterwards each repo in Forgejo has a push mirror (repo > Settings > Repository >
#      Mirror settings) that pushes to GitHub on every commit and every 8 hours.
#   The mirror token is stored inside Forgejo, so it is also in the STEP 9 dumps.
{ lib, config, pkgs-stable, username, inputs, ... }:
let
  inherit (import ./vars.nix) dataDir secretsDir domain;
  gitHost = "git.${domain}";

  # Second copy of the nightly Forgejo dump, on the big drive (a different disk from
  # /var/lib/forgejo). Owned by you and closed to everyone else, because a dump holds
  # Forgejo's secrets and password hashes. Syncthing sends this folder to the desktop.
  forgejoBackupDir = "${dataDir}/backups/forgejo";
  copyForgejoDump = pkgs-stable.callPackage ../../../packages/server-scripts/forgejo-dump-copy.nix {
    inherit username;
    dumpDir = config.services.forgejo.dump.backupDir;
    backupDir = forgejoBackupDir;
  };
in {
  imports = [ inputs.forgesync.nixosModules.default ];

  config = lib.mkIf config.my.isServer {
    services = {
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

      # Runs daily and creates any missing GitHub repos and push mirrors (STEP 13). Talks
      # to Forgejo on localhost rather than through the tunnel. Forgejo itself then
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
    };

    systemd = {
      tmpfiles.rules = [ "d ${forgejoBackupDir} 0700 ${username} users -" ];
      services = {
        # The module's nightly dump stays on /var/lib/forgejo, so as soon as a dump
        # succeeds, copy it to the big drive. A failed dump copies nothing.
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
      };
    };

    # The `forgejo` command for admin tasks (STEP 9)
    environment.systemPackages = [ config.services.forgejo.package ];
  };
}
