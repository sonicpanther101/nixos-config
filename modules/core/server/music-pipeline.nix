# ─── Music pipeline: Lidarr hook + phone music ───────────────────────────
# Everything that happens to the library after Lidarr imports an album, plus the
# phone-sized copy of it. The scripts live in packages/ (lidarr-hook.nix,
# phone-music-sync.nix, server-scripts/music-permissions.nix).
#
# STEP 14 — Lidarr post-import hook (lyrics, ReplayGain, cover + artist images, and
#   no more "twenty one pilots" folders next to "Twenty One Pilots"). One-time, in the
#   Lidarr web UI (http://<lanIp>:8686/), after the rebuild:
#   a. Settings > Connect > + > Custom Script. Name: Pipeline hook. Path:
#        /run/current-system/sw/bin/lidarr-hook
#      Tick: On Import, On Upgrade, On Artist Add. Leave the rest off, press Test, Save.
#   b. Settings > Media Management > Tag Audio Files with Metadata: switch it off (or
#      "new downloads only"). The hook already adopts your library's spelling of the
#      artist tags, but then Lidarr isn't fighting your own tagging either.
#   Then, once, for the library you already have (run as the lidarr user so the state
#   and log files end up where the hook expects them):
#      sudo -u lidarr lidarr-hook --fix-case /srv/data/Music            # shows split folders
#      sudo -u lidarr lidarr-hook --fix-case /srv/data/Music --apply    # merges them
#      sudo -u lidarr lidarr-hook --sweep /srv/data/Music --dry-run     # what is missing
#      sudo -u lidarr lidarr-hook --sweep /srv/data/Music               # fill it in
#   Log: /var/lib/lidarr/.config/Lidarr/hook/hook.log. Tracks that need a person (lyrics
#   only unsynced, or not found anywhere) are listed in hook/needs_attention.tsv.
#
# STEP 15 — Phone music (about 100 GB: the albums you play most + the newest ones):
#   Every hour phone-music-sync picks whole albums by Last.fm play count and by date
#   added, and mirrors them as hard links (no extra disk space, same Artist/Year - Album
#   layout as the library) into ${dataDir}/PhoneMusic. Syncthing sends that folder to the
#   phone, so albums that fall out of the set are removed from the phone too. Lidarr
#   only ever sees Music/, which this never changes.
#   a. Last.fm: create a free API key at https://www.last.fm/api/account/create (any
#      name), make sure your Last.fm profile's listening activity is public, then:
#        sudo tee /var/lib/server-secrets/lastfm.env <<'EOF'
#        LASTFM_API_KEY=paste-the-key
#        LASTFM_USER=your-lastfm-username
#        EOF
#        sudo chmod 600 /var/lib/server-secrets/lastfm.env
#   b. Preview, then run it for real (it also runs on its own every hour):
#        sudo phone-music-sync --dry-run
#        sudo systemctl start phone-music-sync ; journalctl -u phone-music-sync -n 40
#   c. Phone (Syncthing): remove the old full "Music" folder (it is no longer shared
#      with the phone), accept the "Phone Music" share and set its type to Receive Only.
#   Size and mix are budgetGb and topShare in the phoneMusicSync call below (100 GB, 60% most
#   played, the rest newest). Last.fm albums are matched to folders by artist and album
#   name (case, accents, punctuation, the year prefix and "(Deluxe)" tails are ignored);
#   the dry run lists your most played Last.fm albums that found no folder, so you can
#   see if any need renaming. Plays only count if the phone player scrobbles to Last.fm.
{ lib, config, pkgs-stable, username, ... }:
let
  inherit (import ./vars.nix) dataDir secretsDir;

  fixMusicPerms = pkgs-stable.callPackage ../../../packages/server-scripts/music-permissions.nix {
    musicDir = "${dataDir}/Music";
  };

  lidarrHookState = "${config.services.lidarr.dataDir}/hook";
  lidarrHook = pkgs-stable.callPackage ../../../packages/lidarr-hook.nix {
    stateDir = lidarrHookState;
    lidarrDataDir = config.services.lidarr.dataDir;
  };

  phoneMusicSync = pkgs-stable.callPackage ../../../packages/phone-music-sync.nix {
    musicDir = "${dataDir}/Music";
    outDir = "${dataDir}/PhoneMusic";
    inherit secretsDir;
    budgetGb = "100";   # size of the phone copy
    topShare = "0.6";   # share of it filled with the most played albums first
  };
in {
  config = lib.mkIf config.my.isServer {
    systemd.services = {
      # Runs as root before every Lidarr start and on boot/rebuild (see fixMusicPerms).
      # Skipped if the big drive isn't mounted.
      music-permissions = {
        description = "Make the Music folder group-writable for Lidarr";
        before = [ "lidarr.service" ];
        wantedBy = [ "multi-user.target" "lidarr.service" ];
        unitConfig.RequiresMountsFor = dataDir;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = fixMusicPerms;
        };
      };

      # The hook queues each import and a detached worker does the slow part. If Lidarr
      # restarts mid-job (a rebuild, say) the job file is still in the queue; this picks
      # any such leftovers up every 15 minutes, and is skipped when the queue is empty.
      lidarr-hook-drain = {
        description = "Finish queued Lidarr hook jobs";
        startAt = "*:0/15";
        unitConfig = {
          RequiresMountsFor = dataDir;
          ConditionDirectoryNotEmpty = "${lidarrHookState}/queue";
        };
        serviceConfig = {
          Type = "oneshot";
          User = config.services.lidarr.user;
          Group = "users";
          UMask = "0002";
          Nice = 10;
          IOSchedulingClass = "idle";
          ExecStart = "${lidarrHook}/bin/lidarr-hook --worker";
        };
      };

      # Rebuilds the phone-sized copy of the library every hour (STEP 15). Runs as you
      # so Syncthing, which also runs as you, owns what it makes. Skipped quietly until
      # the Last.fm key file exists, and never prunes if Last.fm can't be reached.
      phone-music-sync = {
        description = "Pick the albums to sync to the phone";
        startAt = "hourly";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        unitConfig = {
          RequiresMountsFor = dataDir;
          ConditionPathExists = "${secretsDir}/lastfm.env";
        };
        serviceConfig = {
          Type = "oneshot";
          User = username;
          Group = "users";
          UMask = "0002";
          Nice = 10;
          IOSchedulingClass = "idle";
          LoadCredential = "lastfm.env:${secretsDir}/lastfm.env";   # root reads it, the service gets a copy
          ExecStart = "${phoneMusicSync}/bin/phone-music-sync";
        };
      };
    };

    # `lidarr-hook` (STEP 14) and `phone-music-sync` (STEP 15) for running by hand
    environment.systemPackages = [ lidarrHook phoneMusicSync ];
  };
}
