{ pkgs-stable, ... }:

pkgs-stable.appimageTools.wrapType2 rec {
  pname = "bambu-studio";
  version = "02.04.00.70";
  ubuntu_version = "24.04_PR-8834";

  src = pkgs-stable.fetchurl {
    url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/Bambu_Studio_ubuntu-${ubuntu_version}.AppImage";
    sha256 = "sha256:26bc07dccb04df2e462b1e03a3766509201c46e27312a15844f6f5d7fdf1debd";
  };

  extraPkgs = pkgs: with pkgs-stable; [
    cacert
    glib
    glib-networking
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    webkitgtk_4_1
  ];

  profile = ''
    export SSL_CERT_FILE="${pkgs-stable.cacert}/etc/ssl/certs/ca-bundle.crt"
    export GIO_MODULE_DIR="${pkgs-stable.glib-networking}/lib/gio/modules/"
  '';
}
