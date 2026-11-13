# Phone music selection (STEP 15 in modules/core/server/music-pipeline.nix). The Python
# lives in ./phone-music-sync. budgetGb is the size of the phone copy, topShare how much of
# it goes to the most played albums first (the rest, and anything left over, goes to the
# newest albums).
{ lib, writeShellScriptBin, python3, findutils, musicDir, outDir, secretsDir, budgetGb ? "100", topShare ? "0.6" }:

writeShellScriptBin "phone-music-sync" ''
  export PATH=${lib.makeBinPath [ findutils ]}:$PATH
  # The artist folders sit one level down, in Music/My Playlist/ (the Lidarr root folder)
  export PHONE_SYNC_MUSIC="${musicDir}/My Playlist"
  export PHONE_SYNC_OUT=${outDir}
  export PHONE_SYNC_BUDGET_GB=${budgetGb}
  export PHONE_SYNC_TOP_SHARE=${topShare}
  export PHONE_SYNC_ENV_FILE=''${PHONE_SYNC_ENV_FILE:-${secretsDir}/lastfm.env}
  exec ${python3}/bin/python \
    ${./phone-music-sync}/phone_music_sync.py "$@"
''
