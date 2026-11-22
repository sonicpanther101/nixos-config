# Keeps qBittorrent and slskd from crowding everyone else off the internet (see
# modules/core/server/bandwidth.nix). The Python lives in ./bulk-shaper. Installed as
# `bulk-shaper`, so `bulk-shaper status` shows what it is doing right now.
# iface is the network card the internet comes in on, users are the accounts whose internet
# traffic is limited. The Mbit numbers are the most they may use while nobody else is
# online (max) and the least they are squeezed to while somebody else is busy (min).
{ lib, writeShellScriptBin, python3, iproute2, nftables, iputils, coreutils
, iface, users
, maxDownMbit, maxUpMbit, minDownMbit, minUpMbit
, lineMbit ? 1000
, badMs ? 25
, goodMs ? 10
, reflectors ? [ "1.1.1.1" "8.8.8.8" "9.9.9.9" ]
}:

writeShellScriptBin "bulk-shaper" ''
  export PATH=${lib.makeBinPath [ iproute2 nftables iputils coreutils ]}:$PATH
  export BULK_IFACE=${iface}
  export BULK_USERS=${lib.concatStringsSep "," users}
  export BULK_MAX_DOWN_MBIT=${toString maxDownMbit}
  export BULK_MAX_UP_MBIT=${toString maxUpMbit}
  export BULK_MIN_DOWN_MBIT=${toString minDownMbit}
  export BULK_MIN_UP_MBIT=${toString minUpMbit}
  export BULK_LINE_MBIT=${toString lineMbit}
  export BULK_BAD_MS=${toString badMs}
  export BULK_GOOD_MS=${toString goodMs}
  export BULK_REFLECTORS="${lib.concatStringsSep " " reflectors}"
  exec ${python3}/bin/python \
    ${./bulk-shaper}/bulk_shaper.py "$@"
''
