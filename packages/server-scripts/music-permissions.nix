# Lidarr runs as group `users` and must be able to create album folders inside
# artist folders that were made by you, Syncthing or Nextcloud (often 0755, owner
# only). This gives the group read+write on everything in Music and makes folders
# setgid so new ones keep the group. `X` adds execute to folders only, not files.
{ writeShellScript, coreutils, findutils, musicDir }:

writeShellScript "music-permissions" ''
  set -eu
  ${coreutils}/bin/chgrp -R users ${musicDir}
  ${coreutils}/bin/chmod -R g+rwX ${musicDir}
  ${findutils}/bin/find ${musicDir} -type d -exec ${coreutils}/bin/chmod g+s {} +
''
