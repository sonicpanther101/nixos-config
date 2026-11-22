# ─── Bandwidth sharing: qBittorrent + slskd stay polite ──────────────────
# Both apps share one speed budget on the internet link (500 Mbit fibre):
#   - up to maxDownMbit / maxUpMbit while nobody else is using the connection
#   - squeezed towards minDownMbit / minUpMbit while somebody else is (a video call,
#     a stream, a big download on another device)
# The server can't see other devices' traffic, so it watches the link's latency instead:
# when someone saturates the fibre, pings to the internet jump up, and the cap is cut
# within a few seconds; once pings are back to normal it climbs back up. Only the
# internet traffic of the apps is limited, nothing on the LAN and nothing else on the
# server (Jellyfin, Nextcloud ...). How it works is explained in packages/bulk-shaper/.
#
# No setup steps. Look at what it is doing with:
#   bulk-shaper status
#   journalctl -u bulk-shaper -f
# To turn it off for a while:  sudo systemctl stop bulk-shaper   (removes all limits)
{ lib, config, pkgs-stable, ... }:
let
  inherit (import ./vars.nix) wanInterface;

  # ─── The numbers to change ─────────────────────────────────────────────
  maxDownMbit = 200;   # what the apps may use while the house is quiet (fibre: 500)
  minDownMbit = 20;    # the least they are squeezed to while somebody else is busy
  # Upload: keep this well under your plan's UPLOAD speed (check it: if the plan is
  # 500 down / 100 up, 100 would fill the whole upload and hurt everyone else).
  maxUpMbit = 40;
  minUpMbit = 10;

  shaper = pkgs-stable.callPackage ../../../packages/bulk-shaper.nix {
    iface = wanInterface;
    users = [ config.services.qbittorrent.user config.services.slskd.user ];
    inherit maxDownMbit minDownMbit maxUpMbit minUpMbit;
    # Gigabit network card. How far latency may rise before it counts as "somebody is
    # using the link" (badMs) or has settled back to normal (goodMs) can also be set here.
    lineMbit = 1000;
  };
in {
  config = lib.mkIf config.my.isServer {
    environment.systemPackages = [ shaper ];   # for `bulk-shaper status`

    boot.kernelModules = [ "ifb" ];   # virtual card used to shape downloads

    systemd.services.bulk-shaper = {
      description = "Limit qBittorrent and slskd when others are using the internet";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = "${shaper}/bin/bulk-shaper run";
        ExecStopPost = "${shaper}/bin/bulk-shaper teardown";   # always remove the limits on stop
        RuntimeDirectory = "bulk-shaper";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };
  };
}
