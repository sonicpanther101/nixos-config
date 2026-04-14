{pkgs-stable, ...}: let
in {
  home.packages = map (name: 
    pkgs-stable.writeScriptBin name (builtins.readFile ./${name}.sh)
  ) [
    "my-install"
    "my-shutdown"
    "my-sleep"
    "my-clean"
    "my-update"
    "my-icon-browser"
    "my-refresh"
    "focus-move"
    "maxfetch"
    "syncthing-usb"
  ];
}