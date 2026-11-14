# ─── Soularr: Lidarr <-> Soulseek ────────────────────────────────────────
# Prowlarr can't search Soulseek (it only speaks torrent / Usenet indexers). Soularr is
# the bridge: every 10 minutes it reads Lidarr's wanted list, searches slskd, downloads
# the best match and tells Lidarr to import it. Quality, all automatic:
#   * FLAC is tried first (every release of the album), MP3 only if no FLAC turns up.
#   * Every finished FLAC goes through the fake-FLAC check (packages/music-pipeline/
#     flac_check.py) before Lidarr sees it. Transcoded MP3/AAC is deleted and the album
#     stays wanted. The uploader is skipped for 3 days (14, then 60 if it keeps
#     happening); a borderline cutoff only costs them a day, and if a second uploader
#     shows the same cutoff the album is taken as genuinely band-limited and imported.
#     Two uploaders with clearly fake FLACs: FLAC is dropped for that album for a week
#     and the MP3 fallback is used.
#   * Albums that already have files (an MP3 from the fallback) are searched for FLAC
#     only, so a real FLAC replaces the MP3 as soon as one shows up. A failed import is
#     retried after a week instead of never.
#
# STEP 16 — Soularr (after the rebuild):
#   a. Lidarr web UI (http://<lanIp>:8686/):
#      Settings > Profiles > Quality Profiles: in the profile your artists use, allow
#      FLAC, MP3-320 and MP3-VBR-V0 (tick more below that only if you accept them),
#      set the cutoff to FLAC and tick "Upgrades Allowed". Allowed = Lidarr takes the
#      MP3 fallback; cutoff FLAC = an MP3 album counts as "wanted" and gets upgraded.
#      A quality that is not ticked is refused at import (and retried after a week).
#      Also check Settings > Media Management > Root Folders: it should be
#      "/srv/data/Music/My Playlist" (that is where imported albums end up).
#   b. Nothing to configure for Soularr or slskd: the Lidarr key is read from Lidarr's
#      config.xml at start, and slskd's key lives in vars.nix.
#   c. Run it now instead of waiting for the timer (a run takes a while, since it searches,
#      downloads and waits for the transfers; `start` without --no-block would sit there
#      until it finishes):
#        sudo systemctl start --no-block soularr ; journalctl -u soularr -f
#      Its own log: /var/lib/soularr/soularr.log. Downloads show up in slskd's web UI.
#   Files that Lidarr refused go to ${dataDir}/slskd/downloads/failed_imports/.
#   Uploaders caught with fake FLACs: /var/lib/soularr/fake_users.json (set or delete
#   the "until" date to let one off early). Check files by hand:
#      lidarr-hook --check-fake "/srv/data/Music/My Playlist/SomeArtist"
#   Quality list: allowed_filetypes below, best first. MP3 files from the fallback get
#   no lyrics/ReplayGain/images from the Lidarr hook (it is FLAC-only); they do when
#   the album is upgraded to FLAC.
{ lib, config, pkgs-stable, ... }:
let
  inherit (import ./vars.nix) dataDir slskdApiKey;

  soularr = pkgs-stable.callPackage ../../../packages/soularr.nix { };
  downloads = config.services.slskd.settings.directories.downloads;
  lidarrConfigXml = "${config.services.lidarr.dataDir}/config.xml";

  # @LIDARR_API_KEY@ is filled in at start, so the key never lands in the nix store
  configTemplate = pkgs-stable.writeText "soularr-config.ini" ''
    [Lidarr]
    api_key = @LIDARR_API_KEY@
    host_url = http://127.0.0.1:8686
    # Soularr runs on the same machine as Lidarr and slskd, so both see the same path
    download_dir = ${downloads}
    disable_sync = False

    [Slskd]
    api_key = ${slskdApiKey}
    host_url = http://127.0.0.1:5030
    url_base = /
    download_dir = ${downloads}
    delete_searches = True
    stalled_timeout = 3600

    [Release Settings]
    use_selected_lidarr_release = False
    use_most_common_tracknum = True
    allow_multi_disc = True
    accepted_countries = Europe,Japan,United Kingdom,United States,[Worldwide],Australia,Canada
    skip_region_check = False
    accepted_formats = CD,Digital Media,Vinyl

    [Search Settings]
    search_timeout = 5000
    maximum_peer_queue = 50
    minimum_peer_upload_speed = 0
    minimum_filename_match_ratio = 0.8
    minimum_search_interval = 5
    # Best first: FLAC (CD quality, then any), then MP3 only if no FLAC exists.
    # "flac" alone accepts any bit depth / sample rate; "mp3 320" needs exactly 320 kbps,
    # plain "mp3" takes anything (VBR files report odd bitrates), Lidarr's quality
    # profile decides what it will actually import.
    allowed_filetypes = flac 16/44.1,flac,mp3 320,mp3
    ignored_users =
    album_prepend_artist = False
    search_type = incrementing_page
    number_of_albums_to_grab = 10
    # "all" = missing albums, plus ones Lidarr wants to upgrade to your quality cutoff
    search_source = all
    # don't search an album again for 3 days after nothing was found (for MP3 albums
    # this is how often the upgrade search for a real FLAC repeats)
    search_retry_wait_hours = 72
    failed_import_denylist = True
    ignore_failed_users = True
    failed_user_ignore_hours = 168

    [Download Settings]
    download_filtering = True
    use_extension_whitelist = False
    rename_download_folders = True

    [Logging]
    level = INFO
    format = [%(levelname)s|%(module)s|L%(lineno)d] %(asctime)s: %(message)s
    datefmt = %Y-%m-%dT%H:%M:%S%z
    log_to_file = True
    log_file = soularr.log
    max_bytes = 1048576
    backup_count = 3
  '';

  run = pkgs-stable.writeShellScript "soularr-run" ''
    set -eu
    state=/var/lib/soularr
    key=$(${pkgs-stable.gnused}/bin/sed -n 's:.*<ApiKey>\(.*\)</ApiKey>.*:\1:p' ${lidarrConfigXml})
    if [ -z "$key" ]; then
      echo "couldn't read Lidarr's API key from ${lidarrConfigXml} (has Lidarr started once?)" >&2
      exit 1
    fi
    umask 077
    ${pkgs-stable.gnused}/bin/sed "s|@LIDARR_API_KEY@|$key|" ${configTemplate} > "$state/config.ini"
    umask 0002
    # --no-lock-file: systemd already guarantees one run at a time, and a lock file left
    # by a crash would block every later run
    exec ${soularr}/bin/soularr --config-dir "$state" --var-dir "$state" --no-lock-file
  '';
in {
  config = lib.mkIf config.my.isServer {
    systemd.services.soularr = {
      description = "Soularr: fetch wanted Lidarr albums from Soulseek";
      startAt = "*:0/10";
      after = [ "lidarr.service" "slskd.service" "network-online.target" ];
      wants = [ "network-online.target" ];
      unitConfig.RequiresMountsFor = dataDir;
      serviceConfig = {
        Type = "oneshot";
        # Same user as Lidarr: it reads Lidarr's config.xml and can move the finished
        # downloads (group `users`, like slskd) into the folder Lidarr imports from.
        User = config.services.lidarr.user;
        Group = "users";
        UMask = "0002";
        StateDirectory = "soularr";
        Nice = 10;
        IOSchedulingClass = "idle";
        TimeoutStartSec = "3h";   # one run waits for its downloads
        ExecStart = run;
      };
    };

    environment.systemPackages = [ soularr ];
  };
}
