# Copies the nightly Forgejo dump to the big drive (see STEP 9 in modules/core/server/forgejo.nix).
{ writeShellScript, rsync, findutils, username, dumpDir, backupDir }:

writeShellScript "forgejo-dump-copy" ''
  set -eu
  # No --delete: this folder keeps more history than the 1 week Forgejo keeps itself
  ${rsync}/bin/rsync -a --chown=${username}:users --chmod=F600 \
    ${dumpDir}/ ${backupDir}/
  # Keep 30 days
  ${findutils}/bin/find ${backupDir} -maxdepth 1 -type f -mtime +30 -delete
''
