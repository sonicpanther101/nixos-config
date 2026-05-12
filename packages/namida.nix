{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, gtk3
, glib
, libX11
, libXext
, libGL
, libepoxy
, libxkbcommon
, pango
, cairo
, atk
, gdk-pixbuf
, alsa-lib
, mesa
, vulkan-loader
, mpv-unwrapped
, libayatana-appindicator
}:

stdenv.mkDerivation rec {
  pname = "namida";
  version = "6.0.6-beta";

  src = fetchurl {
    url = "https://github.com/namidaco/namida-snapshots/releases/download/6.0.6-beta%2B260501142/namida-v6.0.6-beta.linux.tar.gz";
    sha256 = "sha256-d7Y31eBGE6rowY581Cx2XTGQsnF7Ob5ffCkjQMBYSCQ=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  # Libraries needed to patch ELF RPATH entries
  buildInputs = [
    gtk3
    glib
    libX11
    libXext
    libGL
    libepoxy
    libxkbcommon
    pango
    cairo
    atk
    gdk-pixbuf
    alsa-lib
    mesa
    vulkan-loader
  ];

  # Resolved at runtime (dlopen'd), not linked
  runtimeDependencies = [
    mpv-unwrapped
    libayatana-appindicator
  ];

  sourceRoot = ".";
  dontBuild = true;
  dontStrip = true;

  preFixup = ''
    addAutoPatchelfSearchPath $out/opt/namida/lib
  '';

  installPhase = ''
    runHook preInstall

    install -dm755 $out/opt/namida

    install -Dm755 namida $out/opt/namida/namida

    if [ -f namida_bin ]; then
      install -Dm755 namida_bin $out/opt/namida/namida_bin
    fi

    if [ -d bin ]; then
      cp -r bin $out/opt/namida/bin
      chmod -R +x $out/opt/namida/bin
    fi

    if [ -d lib ]; then
      cp -r lib $out/opt/namida/lib
    fi

    if [ -d data ]; then
      cp -r data $out/opt/namida/data
    fi

    if [ -f share/applications/namida.desktop ]; then
      install -Dm644 share/applications/namida.desktop \
        $out/share/applications/namida.desktop
      substituteInPlace $out/share/applications/namida.desktop \
        --replace "Exec=namida" "Exec=$out/bin/namida"
    fi

    if [ -f share/metainfo/namida.metainfo.xml ]; then
      install -Dm644 share/metainfo/namida.metainfo.xml \
        $out/share/metainfo/namida.metainfo.xml
    fi

    for size in 128 256 512; do
      icon="share/icons/namida_''${size}.png"
      if [ -f "$icon" ]; then
        install -Dm644 "$icon" \
          "$out/share/icons/hicolor/''${size}x''${size}/apps/namida.png"
      fi
    done

    makeWrapper $out/opt/namida/namida $out/bin/namida \
      --prefix LD_LIBRARY_PATH : "$out/opt/namida/lib" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        mesa
        vulkan-loader
        mpv-unwrapped
        libayatana-appindicator
      ]}"

    runHook postInstall
  '';

  autoPatchelfIgnoreMissingDeps = true;

  meta = with lib; {
    description = "Beautiful music & video player for local libraries and YouTube";
    homepage = "https://github.com/namidaco/namida";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
    mainProgram = "namida";
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
