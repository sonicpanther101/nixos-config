# ─── Kiwix ───────────────────────────────────────────────────────────────
# Offline Wikipedia and friends, reachable at http://<lanIp>:8080/
#
# STEP 4 — Kiwix serves every .zim file in /srv/data/kiwix and needs at least one.
#   Pick files from https://download.kiwix.org/zim/ then:
#     cd /srv/data/kiwix && curl -LO <zim-url>
#     sudo systemctl restart kiwix-serve   (the folder is re-scanned on every start)
#   (Until the folder has something in it the kiwix-serve unit is just skipped.)
{ lib, config, pkgs-stable, username, ... }:
let
  inherit (import ./vars.nix) dataDir;

  # Every .zim in ${dataDir}/kiwix is added to this library file each time the
  # service starts (ExecStartPre below).
  kiwixLibrary = "/var/lib/kiwix/library.xml";
  refreshKiwixLibrary = pkgs-stable.callPackage ../../../packages/server-scripts/kiwix-refresh-library.nix {
    kiwixPackage = config.services.kiwix-serve.package;
    zimDir = "${dataDir}/kiwix";
    libraryPath = kiwixLibrary;
  };
in {
  config = lib.mkIf config.my.isServer {
    services.kiwix-serve = {
      enable = true;
      port = 8080;
      openFirewall = true;
      libraryPath = kiwixLibrary;
    };

    systemd = {
      tmpfiles.rules = [ "d ${dataDir}/kiwix 0755 ${username} users -" ];
      services.kiwix-serve = {
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
    };
  };
}
