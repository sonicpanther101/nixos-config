{ username, config, lib, pkgs, ... } :
let
  # pam_exec (with expose_authtok) hands us whatever was typed/"pressed" on
  # stdin. We just compare it to the hardcoded, base64-encoded PIN and exit
  # 0 (success) or 1 (failure). This is NOT real encryption -- it only stops
  # the PIN being readable at a glance in this file / `nix store`. Treat it
  # like a bike lock combo, not a password.
  pinCheckScript = pkgs.writeShellScript "hyprlock-pin-check" ''
    set -euo pipefail
    entered="$(cat)"
    expected="$(printf '%s' "${config.my.pinLoginCode}" | base64 -d 2>/dev/null || true)"
    if [ -n "$expected" ] && [ "$entered" = "$expected" ]; then
      exit 0
    fi
    exit 1
  '';
in {
  security = {
    rtkit.enable = true;
    pam.services.hyprlock = {
      enable = true;
      # Tried before the normal password check ("sufficient" + earlier
      # order): if the PIN matches, auth succeeds immediately; if not,
      # it just falls through to the real password like normal. Disabled
      # entirely unless my.hasPinLogin is set for this host.
      rules.auth.pin = {
        enable = config.my.hasPinLogin;
        control = "sufficient";
        modulePath = "${pkgs.pam}/lib/security/pam_exec.so";
        args = [ "expose_authtok" "quiet" "${pinCheckScript}" ];
        order = config.security.pam.services.hyprlock.rules.auth.unix.order - 10;
      };
    };
    polkit.enable = true;
  };
}