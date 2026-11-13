# Soularr (https://github.com/mrusse/soularr): the script that takes Lidarr's wanted
# list, finds the albums on Soulseek through slskd and tells Lidarr to import them.
# It isn't in nixpkgs, and neither is its slskd-api library, so both are built here.
#
# The `soularr` command is not stock Soularr: it starts soularr_gate.py (in
# ./music-pipeline), which runs Soularr unchanged but checks every finished download with
# flac_check.py first, so fake FLACs never reach Lidarr. Used by
# modules/core/server/soularr.nix.
{ lib, stdenvNoCC, python3, fetchFromGitHub, fetchPypi, makeWrapper, ffmpeg-headless }:

let
  slskdApi = python3.pkgs.buildPythonPackage rec {
    pname = "slskd-api";
    version = "0.1.5";
    pyproject = true;
    build-system = [ python3.pkgs.setuptools python3.pkgs.setuptools-git-versioning ];
    dependencies = [ python3.pkgs.requests ];
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-LmWP7bnK5IVid255qS2NGOmyKzGpUl3xsO5vi5uJI88=";
    };
    doCheck = false;
    pythonImportsCheck = [ "slskd_api" ];
  };

  pythonEnv = python3.withPackages (ps: [
    ps.music-tag
    ps.pyarr
    ps.requests
    ps.mutagen    # flac_check.py
    ps.numpy      # flac_check.py
    slskdApi
  ]);
in
stdenvNoCC.mkDerivation rec {
  pname = "soularr";
  version = "1.2.3";

  src = fetchFromGitHub {
    owner = "mrusse";
    repo = "soularr";
    tag = "v${version}";
    hash = "sha256-2ipDV1oOlO06ZSjhhzyMRVdoGtdDtSo8ND3ijJqJTKg=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/libexec/soularr $out/bin
    cp soularr.py $out/libexec/soularr/
    cp ${./music-pipeline/soularr_gate.py} $out/libexec/soularr/soularr_gate.py
    cp ${./music-pipeline/flac_check.py} $out/libexec/soularr/flac_check.py
    makeWrapper ${pythonEnv}/bin/python $out/bin/soularr \
      --add-flags $out/libexec/soularr/soularr_gate.py \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg-headless ]}
  '';

  meta = {
    description = "Lidarr to Soulseek bridge (with a fake-FLAC check before import)";
    homepage = "https://github.com/mrusse/soularr";
    license = lib.licenses.gpl3Only;
    mainProgram = "soularr";
  };
}
