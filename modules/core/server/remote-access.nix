# ─── Remote access: Cloudflare Tunnel, Tailscale, headless Sunshine ──────
# From outside the house everything goes through the Cloudflare Tunnel, and the
# remote desktop (Sunshine/Moonlight) goes through Tailscale. See the server
# setup guide for the domain, tunnel and Sunshine steps.
#
# STEP 7 — Cloudflare Tunnel token (from the Cloudflare dashboard, see the guide):
#   sudo tee /var/lib/server-secrets/cloudflared.env <<'EOF'
#   TUNNEL_TOKEN=paste-the-long-token-here
#   EOF
#   sudo chmod 600 /var/lib/server-secrets/cloudflared.env
#   sudo systemctl restart cloudflared
#
# STEP 8 — Tailscale (remote desktop from other networks):
#   sudo tailscale up
#   (Tailscale itself is enabled for every host in services.nix.)
#
# STEP 12 — Syncthing's web UI through the tunnel (Cloudflare dashboard, no rebuild):
#   a. FIRST protect it: Zero Trust > Access > Applications > Add > Self-hosted for
#      syncthing.<domain>, with a policy that allows only your email.
#   b. Then publish it: Zero Trust > Networks > Tunnels > your tunnel > Published
#      application routes > add syncthing.<domain> -> HTTP localhost:8384, and under
#      Additional application settings > HTTP Settings set "HTTP Host Header" to
#      localhost (Syncthing rejects Host headers it doesn't know).
#   c. In Syncthing: Actions > Settings > GUI, set a GUI user and password as well.
#   Only the web UI goes through the tunnel. Syncing itself (port 22000) can't: it
#   already works over the LAN, Tailscale and Syncthing's own relays.
{ lib, config, pkgs-stable, ... }:
let
  inherit (import ./vars.nix) lanIp secretsDir domain;

  # The video output the Hyprland/Sunshine session draws on. Check yours with:
  #   for f in /sys/class/drm/*/status; do echo "$f: $(cat $f)"; done
  headlessConnector = "HDMI-A-1";
in {
  config = lib.mkIf config.my.isServer {
    # Cloudflare Tunnel: a "remotely managed" tunnel, so the hostname -> port
    # mapping is edited in the Cloudflare dashboard, not here. Skipped quietly
    # until the token file exists (STEP 7).
    systemd.services.cloudflared = {
      description = "Cloudflare Tunnel";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      unitConfig.ConditionPathExists = "${secretsDir}/cloudflared.env";
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs-stable.cloudflared} tunnel --no-autoupdate run";
        EnvironmentFile = "${secretsDir}/cloudflared.env";   # holds TUNNEL_TOKEN=...
        DynamicUser = true;
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # Everything arriving over Tailscale is trusted (it only carries your own devices).
    # Syncthing's sync ports are opened for every host in network.nix.
    networking.firewall.trustedInterfaces = [ "tailscale0" ];

    # Sunshine web UI through the tunnel. Sunshine itself is enabled for every
    # high-power host in services.nix. Its web UI refuses requests from any origin not
    # listed here (CSRF error). Setting any option here makes sunshine.conf read-only,
    # so the web UI's Configuration tab can no longer save changes: edit this list
    # instead. Pairing and logins still work.
    services.sunshine.settings.csrf_allowed_origins = "https://sunshine.${domain},https://${lanIp}:47990,https://127.0.0.1:47990";

    # ─── Headless remote desktop ─────────────────────────────────────────────
    # With no monitor attached the GPU reports "nothing connected" and there is
    # nothing to capture, so force the connector on at 1080p. A real monitor
    # plugged in later still works (it just runs at 1080p60). A cheap HDMI
    # "dummy plug" does the same job in hardware if this is not enough.
    boot.kernelParams = [ "video=${headlessConnector}:1920x1080@60e" ];
  };
}
