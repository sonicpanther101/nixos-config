# Every .zim in ${zimDir} is added to the library file each time kiwix-serve
# starts (runs as ExecStartPre, see modules/core/server/kiwix.nix).
{ lib, writeShellScript, kiwixPackage, zimDir, libraryPath }:

writeShellScript "kiwix-refresh-library" ''
  set -eu
  rm -f ${libraryPath}
  for zim in ${zimDir}/*.zim; do
    [ -e "$zim" ] || continue
    ${lib.getExe' kiwixPackage "kiwix-manage"} ${libraryPath} add "$zim"
  done
''
