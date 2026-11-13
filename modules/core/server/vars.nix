# Values shared by every file in this folder. Plain attribute set (no module
# arguments), so each file reads what it needs with `import ./vars.nix`.
{
  # This machine's LAN address. Check it matches this machine (STEP 2 in default.nix)
  lanIp = "192.168.1.247";

  # Bulk storage. This is a bind mount of ~/driveBig (see default.nix), so the
  # services can reach it without needing access to your home directory.
  dataDir = "/srv/data";

  # Root-only files holding passwords. Never put these in the nix store.
  secretsDir = "/var/lib/server-secrets";

  # API key Soularr uses to talk to slskd. slskd only accepts it from this machine
  # (127.0.0.1), but slskd's settings end up in the nix store, so don't reuse it anywhere.
  slskdApiKey = "nixb7BCvCQk1k5bYkeI4jRCGauyLE84af7uZ_VYDMiw";

  # Your Cloudflare domain. Nextcloud gets cloud.<domain>, Forgejo git.<domain>;
  # every other hostname (dav, sonarr, ...) is added in the Cloudflare dashboard.
  domain = "adambeattie.dev";
}
