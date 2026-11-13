# smartd runs this as root when a drive reports a problem, with the details in
# SMARTD_* variables. It sends a phone push through ntfy.sh to the topic in
# ${secretsDir}/ntfy.env (STEP 11 in modules/core/server/disk-health.nix). It is
# also installed as `smartd-ntfy` so `sudo smartd-ntfy` sends a test message.
# It always exits 0.
{ writeShellScriptBin, util-linux, curl, secretsDir }:

writeShellScriptBin "smartd-ntfy" ''
  set -u
  log() { ${util-linux}/bin/logger -t smartd-ntfy "$*"; }
  [ -r ${secretsDir}/ntfy.env ] && . ${secretsDir}/ntfy.env
  subject="''${SMARTD_SUBJECT:-Test message from smartd-ntfy}"
  log "$subject"
  if [ -z "''${NTFY_TOPIC:-}" ]; then
    log "no NTFY_TOPIC in ${secretsDir}/ntfy.env: push skipped"
    exit 0
  fi
  ${curl}/bin/curl -fsS --max-time 20 \
    -H "Title: $subject" \
    -H "Priority: urgent" \
    -H "Tags: warning,floppy_disk" \
    -d "''${SMARTD_FULLMESSAGE:-This is a test. If you can read it, disk alerts reach you.}" \
    "https://ntfy.sh/$NTFY_TOPIC" >/dev/null || log "ntfy push failed"
  exit 0
''
