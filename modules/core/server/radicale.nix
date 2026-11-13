# ─── Radicale (calendars + tasks) ────────────────────────────────────────
# Reachable at http://<lanIp>:5232/ (login required). Logins live in
# /var/lib/radicale/users (STEP 6).
#
# STEP 6 — Radicale logins (an empty login file is created for you, so Radicale
#   starts but refuses everyone until you add yourself):
#   nix-shell -p apacheHttpd --run "htpasswd -B -c /tmp/radicale-users adam"
#   sudo mv /tmp/radicale-users /var/lib/radicale/users
#   sudo chown radicale:radicale /var/lib/radicale/users && sudo chmod 640 /var/lib/radicale/users
#   (Use -B without -c to add another user later. If you are migrating the old
#   desktop calendars, the user name must match the folder name inside
#   /var/lib/radicale/collections/collection-root/.)
{ lib, config, ... }:
{
  config = lib.mkIf config.my.isServer {
    services.radicale = {
      enable = true;
      settings = {
        server.hosts = [ "0.0.0.0:5232" ];
        auth = {
          type = "htpasswd";
          htpasswd_filename = "/var/lib/radicale/users";
          htpasswd_encryption = "bcrypt";
        };
      };
    };

    systemd.tmpfiles.rules = [
      # The logins file must exist or Radicale refuses to start.
      # `f` only creates it when missing, so your real logins are never touched.
      "d /var/lib/radicale             0750 radicale radicale -"
      "d /var/lib/radicale/collections 0750 radicale radicale -"
      "f /var/lib/radicale/users       0640 radicale radicale -"
    ];

    networking.firewall.allowedTCPPorts = [ 5232 ];
  };
}
