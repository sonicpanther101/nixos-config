# Lidarr post-import hook (STEP 14 in modules/core/server/music-pipeline.nix). The Python
# files live in ./music-pipeline; this gives them a Python with the libraries they need
# and ffmpeg for ReplayGain and the fake-FLAC check. The state dir (queue, log, needs_attention.tsv) sits next to
# Lidarr's own data.
{ lib, writeShellScriptBin, python3, ffmpeg-headless, stateDir, lidarrDataDir }:

writeShellScriptBin "lidarr-hook" ''
  export PATH=${lib.makeBinPath [ ffmpeg-headless ]}:$PATH
  export MUSIC_PIPELINE_STATE=${stateDir}
  export LIDARR_CONFIG_XML=${lidarrDataDir}/config.xml
  exec ${python3.withPackages (ps: [ ps.mutagen ps.requests ps.pillow ps.numpy ])}/bin/python \
    ${./music-pipeline}/lidarr_hook.py "$@"
''
