{ pkgs-stable, inputs, lib, ... }:
inputs.erosanix.lib.${pkgs-stable.stdenv.hostPlatform.system}.mkWindowsAppNoCC rec {
  pname = "tagscanner-win64";
  version = "6.1.21";
  dontUnpack = true;
  enableMonoBootPrompt = false;
  nativeBuildInputs = [
    pkgs-stable.copyDesktopItems
    inputs.erosanix.lib.${pkgs-stable.stdenv.hostPlatform.system}.copyDesktopIcons
  ];
  enableInstallNotification = true;
  inhibitIdle = true;
  wineArch = "win64";
  wine = pkgs-stable.wineWow64Packages.staging;

  src = {
    win64 = pkgs-stable.fetchurl {
      url = "https://www.xdlab.ru/files/tagscan-${version}_x64-setup.exe";
      sha256 = "sha256-YUnkqTvpWT8VFkKQ5KZAmNsHuJotDuPhet/UBexCSZE=";
    };
  }."win64";

  winAppInstall = ''
    set -e
    mkdir -p "$WINEPREFIX/drive_c/${pname}"
    echo "Just click next on everything, don't try to change anything."
    $WINE "${src}" /NORESTART /SP-
  '';

  # Can require you to remove lock file if broken `ls -ld /tmp/*.lock`
  winAppRun = ''
    $WINE "$WINEPREFIX/drive_c/Program Files/TagScanner/Tagscan.exe" "$ARGS"
  '';

  installPhase = ''
    runHook preInstall
    runHook postInstall
  '';

  postInstall = ''
    mv $out/bin/.launcher $out/bin/${pname}
  '';

  desktopItems = [
    (pkgs-stable.makeDesktopItem {
      name = pname;
      exec = pname;
      icon = pname;
      desktopName = "Tagscanner";
      comment = "Advanced Freeware Audio Tagger";
      categories = [ "AudioVideo" "Audio" ];
      mimeTypes = builtins.map (s: "audio/" + s) [ "mpeg" "mp4" "aac" "x-vorbis+ogg" "x-opus+ogg" "flac" "x-wavpack" "x-wav" "x-aiff" "x-musepack" "x-speex" ];
    })
  ];

  desktopIcon = inputs.erosanix.lib.${pkgs-stable.stdenv.hostPlatform.system}.makeDesktopIcon {
    name = pname;
    icoIndex = 0;
    src = pkgs-stable.fetchurl {
      url = "https://www.xdlab.ru/favicon.ico";
      sha256 = "sha256-GWNMjhCQMrxTlN1N4yYt5HRgkucgV65N3LzFg6BoDfQ=";
    };
  };

  meta = with lib; {
    description = "The flexible tool to manage your music collection";
    homepage = "https://www.xdlab.ru/en/index.htm";
    license = licenses.free;
    maintainers = [];
    platforms = [ "i686-linux" "x86_64-linux" ];
  };
}