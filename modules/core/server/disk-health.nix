# ─── Disk health (smartd) ────────────────────────────────────────────────
# Watches every drive it can find (autodetect). When one reports a problem
# smartd runs smartdNotify, which pushes to your phone (STEP 11), and
# repeats the alert daily until it is fixed. The module's own wall/mail
# notifiers are off so only one `-M exec` ends up in smartd.conf.
#   -a                 health, attributes, error log and self-test log
#   -o on              automatic offline data collection
#   -s (S/...|L/...)   short self-test daily 02:00, long self-test Sundays 04:00
#   -m <nomailer>      no email, just run the script
# A drive behind a USB enclosure may need `-d sat`: set autodetect = false and
# list it under `devices = [ { device = "/dev/sdX"; options = "-d sat"; } ];`
#
# STEP 11 — Disk health alerts (smartd pushes to your phone through ntfy.sh):
#   sudo tee /var/lib/server-secrets/ntfy.env <<EOF
#   NTFY_TOPIC=server-disks-$(openssl rand -hex 12)
#   EOF
#   sudo chmod 600 /var/lib/server-secrets/ntfy.env
#   sudo cat /var/lib/server-secrets/ntfy.env
#   Install the ntfy app on your phone and subscribe to that exact topic name (the
#   topic is the only secret, so don't share it). Then send yourself a test:
#     sudo smartd-ntfy
#   List what smartd is watching with:  sudo smartctl --scan   and   journalctl -u smartd
#   (A drive in a USB enclosure may need `-d sat`: see the smartd note below.)
{ lib, config, pkgs-stable, ... }:
let
  inherit (import ./vars.nix) secretsDir;

  smartdNotify = pkgs-stable.callPackage ../../../packages/server-scripts/smartd-ntfy.nix {
    inherit secretsDir;
  };
in {
  config = lib.mkIf config.my.isServer {
    services.smartd = {
      enable = true;
      notifications = {
        wall.enable = false;
        mail.enable = false;
        x11.enable = false;
      };
      defaults.monitored = "-a -o on -s (S/../.././02|L/../../7/04) -m <nomailer> -M exec ${lib.getExe smartdNotify}";
    };

    # smartctl for checking drives by hand, and the `smartd-ntfy` test command
    environment.systemPackages = [ pkgs-stable.smartmontools smartdNotify ];
  };
}
