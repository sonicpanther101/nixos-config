# qBittorrent rewrites its own config, so instead of owning the whole file
# (which would wipe your web UI password) this only pins the few settings
# needed to sit safely behind the tunnel, before every start.
{ writeShellScript, crudini, confPath }:

writeShellScript "qbittorrent-configure" ''
  set -eu
  mkdir -p "$(dirname ${confPath})"
  set_pref() {
    ${crudini}/bin/crudini --ini-options=nospace --set ${confPath} Preferences "$1" "$2"
  }
  set_pref 'WebUI\HostHeaderValidation' false      # accept the public hostname
  set_pref 'WebUI\LocalHostAuth' true              # cloudflared connects from localhost: never skip the login
  set_pref 'WebUI\ReverseProxySupportEnabled' true # use the real visitor IP for login bans
  set_pref 'WebUI\TrustedReverseProxiesList' 127.0.0.1
''
