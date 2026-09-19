{ lib, stdenv, wayland, wayland-scanner, pkg-config }:

stdenv.mkDerivation {
  pname = "wl-monitor-invert";
  version = "1.0.0";

  src = ./wl-monitor-invert;

  nativeBuildInputs = [ wayland-scanner pkg-config ];
  buildInputs = [ wayland ];

  buildPhase = ''
    runHook preBuild

    wayland-scanner client-header \
      wlr-gamma-control-unstable-v1.xml wlr-gamma-control-unstable-v1-client-protocol.h
    wayland-scanner private-code \
      wlr-gamma-control-unstable-v1.xml wlr-gamma-control-unstable-v1-protocol.c

    $CC -Wall -Wextra -O2 -o wl-monitor-invert \
      main.c wlr-gamma-control-unstable-v1-protocol.c \
      $(pkg-config --cflags --libs wayland-client)

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp wl-monitor-invert $out/bin/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Invert the colours of a single Wayland output (per-monitor xcalib -i replacement, via wlr-gamma-control-unstable-v1)";
    homepage = "https://wayland.app/protocols/wlr-gamma-control-unstable-v1";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
