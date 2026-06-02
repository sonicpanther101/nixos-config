{ pkgs-stable, inputs, lib, ... }:
inputs.erosanix.lib.${pkgs-stable.stdenv.hostPlatform.system}.mkWindowsAppNoCC rec {
  pname = "mp3tag-win64";
  version = "3.34.1";
  dontUnpack = true;
  enableMonoBootPrompt = false;
  nativeBuildInputs = [
    pkgs-stable.copyDesktopItems
    inputs.erosanix.lib.${pkgs-stable.stdenv.hostPlatform.system}.copyDesktopIcons
  ];
  enableInstallNotification = true;
  inhibitIdle = true;
  wineArch = "win64";
  wine = pkgs-stable.wineWow64Packages.base;

  src = {
    win64 = pkgs-stable.fetchurl {
      url = "https://www.mp3tag.de/en/dodownload64.html";
      sha256 = "sha256-d0tbG7skXqdhKOyMJQwz0QIT3M3gkcHP1OzPsx81QpY="; #:hash64:
    };
  }."win64";

  winAppInstall = ''
    d="$WINEPREFIX/drive_c/${pname}"

    mkdir -p "$d"
    
  '';

  winAppRun = ''
    $WINE "$WINEPREFIX/drive_c/${pname}/Mp3tag.exe" "$ARGS"
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
      desktopName = "Mp3tag";
      comment = "The universal tag editor and more ...";
      categories = [ "AudioVideo" "Audio" ];
      mimeTypes = builtins.map (s: "audio/" + s) [ "mpeg" "mp4" "aac" "x-vorbis+ogg" "x-opus+ogg" "flac" "x-wavpack" "x-wav" "x-aiff" "x-musepack" "x-speex" ];
    })
  ];

  desktopIcon = inputs.erosanix.lib.${pkgs-stable.stdenv.hostPlatform.system}.makeDesktopIcon {
    name = pname;
    icoIndex = 0;
    src = pkgs-stable.fetchurl {
      url = "https://www.mp3tag.de/favicon.ico";
      sha256 = "sha256-0XuSlQjrGQlQxZnAOjw3+uZX1cHkVBpKffyHbstRPMQ=";
    };
  };

  meta = with lib; {
    description = "The universal tag editor and more ...";
    homepage = "https://www.mp3tag.de/en/";
    license = licenses.free;
    maintainers = [];
    platforms = [ "i686-linux" "x86_64-linux" ];
  };
}
