{
  lib,
  stdenv,
  fetchFromGitLab,
  libusb1,
  hidapi,
  pkg-config,
  coreutils,
  mbedtls,
  symlinkJoin,
  kdePackages,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "openrgb";
  version = "1.0rc2";
  
  src = fetchFromGitLab {
    owner = "CalcProgrammer1";
    repo = "OpenRGB";
    rev = "release_candidate_1.0rc2";
    hash = "sha256-vdIA9i1ewcrfX5U7FkcRR+ISdH5uRi9fz9YU5IkPKJQ=";
  };
  
  nativeBuildInputs = [
    pkg-config
  ]
  ++ (with kdePackages; [
    qmake
    wrapQtAppsHook
  ]);
  
  buildInputs = [
    libusb1
    hidapi
    mbedtls
  ]
  ++ (with kdePackages; [
    qtbase
    qttools
    qtwayland
  ]);
  
  postPatch = ''
    patchShebangs scripts/build-udev-rules.sh
  '';
  
  installPhase = ''
    runHook preInstall
    make install || true
    # Verify the binary was installed
    if [ ! -f "$out/bin/openrgb" ]; then
      echo "Error: openrgb binary not found!"
      exit 1
    fi
    runHook postInstall
  '';
  
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    HOME=$TMPDIR $out/bin/openrgb --help > /dev/null
    runHook postInstallCheck
  '';
  
  qmakeFlags = [
    "QT_TOOL.lrelease.binary=${lib.getDev kdePackages.qttools}/bin/lrelease"
  ];
  
  passthru.withPlugins =
    plugins:
    let
      pluginsDir = symlinkJoin {
        name = "openrgb-plugins";
        paths = plugins;
        postBuild = ''
          for f in $out/lib/*; do
            if [ "$(dirname $(readlink "$f"))" == "." ]; then
              rm "$f"
            fi
          done
        '';
      };
    in
    finalAttrs.finalPackage.overrideAttrs (old: {
      qmakeFlags = old.qmakeFlags or [ ] ++ [
        ''DEFINES+=OPENRGB_EXTRA_PLUGIN_DIRECTORY=\\\""${
          lib.escape [ "\\" "\"" " " ] (toString pluginsDir)
        }/lib\\\""''
      ];
    });
  
  meta = {
    description = "Open source RGB lighting control";
    homepage = "https://gitlab.com/CalcProgrammer1/OpenRGB";
    maintainers = with lib.maintainers; [ johnrtitor ];
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    mainProgram = "openrgb";
  };
})