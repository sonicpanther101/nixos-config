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
    # nothing to capture. Forcing the connector on (`e`) isn't enough on its own: with
    # no EDID the driver only offers generic fallback modes, and Hyprland's "preferred"
    # mode then picked something low and blurry. So the connector is also given a
    # made-up monitor identity (an EDID generated from the standard 1080p60 timing,
    # loaded by the kernel at boot): it reports exactly one mode, 1920x1080 at 60 Hz.
    # Hyprland uses it through the monitor rule in modules/home/hyprland/settings.nix
    # (it names the same connector, keep the two in step). A real monitor plugged into
    # this connector later is limited to 1080p60 too; on another connector it works
    # normally. A cheap HDMI "dummy plug" does the same job in hardware.
    # Check after a reboot:
    #   hyprctl monitors | head -5                  (1920x1080@60.000, scale 1)
    #   cat /sys/class/drm/card*-${headlessConnector}/modes     (only 1920x1080)
    hardware.display = {
      edid.modelines."Dummy1080p60" = "148.50   1920 2008 2052 2200   1080 1084 1089 1125   +hsync +vsync";
      outputs.${headlessConnector} = {
        edid = "Dummy1080p60.bin";
        mode = "1920x1080@60e";
      };
    };
  };
}
