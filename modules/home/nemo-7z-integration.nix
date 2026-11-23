{ config, pkgs-stable, lib, ... }:

let
  # Declaratively fetch the toolkit source
  sevenZipContextMenu = pkgs-stable.fetchFromGitHub {
    owner = "Archeer0";
    repo = "7z-ContextMenu";
    rev = "main"; # Pin to a specific commit for reproducibility
    sha256 = "sha256-g0qO1zT5AVxQl8EH5+RHXqhA5rFP0lYZXeZpatOzLEc=";
  };

  # Path to the installer script inside the fetched source
  installerScript = "${sevenZipContextMenu}/nemo/install_nemo_7z_menu.sh";

  # Marker file to ensure the script runs only once
  markerFile = "${config.home.homeDirectory}/.local/share/nemo/.7z-contextmenu-installed";
in
{
  home.activation.install7zContextMenu = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${markerFile}" ]; then
      echo "Installing 7z Context Menu for Nemo (one-time setup)..."
      run bash "${installerScript}"
      mkdir -p "$(dirname "${markerFile}")"
      touch "${markerFile}"
    fi
  '';
}
