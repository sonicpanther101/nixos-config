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
    "my-sha256"
    "my-add-vscode-ext"
    "my-rwall"
    "my-nixdump"
    "my-screenrecording"
    "my-budgeting"
    "my-mpris-waybar"
    "maxfetch"
    "my-syncthing-usb"
    "my-date-formatter"
    "my-promodoro"
    "my-weather"
    "my-github-contributions"
    "my-toggle-keyboard"
  ];
}