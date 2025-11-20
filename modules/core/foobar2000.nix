{ pkgs, lib, config, pkgs-stable, inputs, username, ... }:

let
  japaneseFonts = pkgs-stable.noto-fonts-cjk-sans;

  # This tells beefweb to launch 'foobar2000'
  foobarPkg = inputs.erosanix.packages.${pkgs-stable.system}.foobar2000.overrideAttrs (oldAttrs: {

    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ japaneseFonts ];

    winAppInstall = ''
      ${oldAttrs.winAppInstall}

      # enable dark mode (doesn't work)
      $WINE reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f
      $WINE reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f

      # get more characters for cjk languages
      WINE_FONTS_DIR="$WINEPREFIX/drive_c/windows/Fonts"

      mkdir -p "$WINE_FONTS_DIR"

      cp -v /home/${username}/nixos-config/modules/core/wqy-microhei.ttc "$WINE_FONTS_DIR"

      regedit.exe /S /home/${username}/nixos-config/modules/core/chn_fonts.reg
    '';
    
    # You might also want to change the name to distinguish it easily
    pname = "foobar2000";
  });

  beefwebConfig = pkgs.writeText "config.yaml" ''
    foobar2000-command: ${foobarPkg}/bin/foobar2000-win64
    host: 127.0.0.1
    port: 8880
    username: ""
    password: ""
    mpris-id: foobar2000
    desktop-entry: foobar2000-mpris
  '';


  aiohttp-sse-client = pkgs-stable.python3Packages.buildPythonPackage rec {
    pname = "aiohttp-sse-client";
    version = "0.2.1";
    src = pkgs-stable.fetchFromGitHub {
      owner = "rtfol";
      repo = "aiohttp-sse-client";
      rev = "v${version}";
      hash = "sha256-rVeUBMTjsnOeZ+ukokP1776Au45LZSdeiqafL3pj5xc="; 
    };
    postPatch = ''
      sed -i "/pytest-runner/d" setup.py
      sed -i 's/setup_requirements/test_requirements/g' setup.py
    '';
    propagatedBuildInputs = with pkgs-stable.python3Packages; [ aiohttp attrs multidict pytest ];
    doCheck = false;
  };

  pyfoobeef = pkgs-stable.python3Packages.buildPythonPackage rec {
    pname = "pyfoobeef";
    version = "0.9.0.4";

    src = pkgs-stable.fetchFromGitHub {
      owner = "Ada-Kru";
      repo = "pyfoobeef";
      rev = "master";
      hash = "sha256-JIr+X3DisLJERltDusR3fF5PacvjhVK1WPRcb/3ce6g=";
    };
    propagatedBuildInputs = with pkgs-stable.python3Packages; [ 
      aiohttp 
      aiohttp-sse-client
      urllib3 
    ];
  };

  mpris-server = pkgs-stable.python3Packages.buildPythonPackage rec {
    pname = "mpris-server";
    version = "0.4.3";
    src = pkgs-stable.fetchFromGitHub {
      owner = "alexdelorenzo";
      repo = "mpris_server";
      rev = "v${version}";
      hash = "sha256-9VEok2eiGKOQDUxBC29z7Y/bQwZc5Ts1prKJMEY7pGs=";
    };
    doCheck = false;
    propagatedBuildInputs = with pkgs-stable.python3Packages; [ pydbus ];
  };

  beefweb-mpris = pkgs-stable.python3Packages.buildPythonApplication rec {
    pname = "beefweb-mpris";
    version = "0.0.1";

    src = pkgs-stable.fetchFromGitHub {
      owner = "ther0n";
      repo = "beefweb_mpris";
      rev = "master";
      hash = "sha256-iDFNZ/dpDlMhUb0uTVIBjmPprWOUFmhy8lZPNu+0/7I="; 
    };

    propagatedBuildInputs = with pkgs-stable.python3Packages; [
      mpris-server
      pyfoobeef
      aiohttp-sse-client
      requests
      pygobject3
      pydbus
      pyyaml
      unidecode
      emoji
    ];

    nativeBuildInputs = [ 
      pkgs-stable.gobject-introspection 
      pkgs-stable.wrapGAppsHook
      pkgs.copyDesktopItems # Add this to install the desktop file
    ];
    
    # Create a nice desktop shortcut for your launcher
    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "foobar2000-mpris";
        desktopName = "Foobar2000 (MPRIS)";
        exec = "beefweb_mpris"; # The python wrapper
        icon = "foobar2000";    # Uses the icon from the main package
        comment = "Foobar2000 with Media Key Support";
        categories = [ "Audio" "Player" ];
      })
    ];
  };

in {
  environment.systemPackages = [
    beefweb-mpris
  ];

  # This uses systemd-tmpfiles to force-create the link at boot/switch.
  # It links ~/.config/beefweb_mpris/config.yaml -> /nix/store/.../config.yaml
  systemd.tmpfiles.rules = [
    "L+ /home/${username}/.config/beefweb_mpris/config.yaml - - - - ${beefwebConfig}"
  ];
  
  # Optional: Auto-start service (if you want it running constantly)
  systemd.user.services.foobar-mpris = {
    description = "Foobar2000 with MPRIS support";
    serviceConfig = {
      ExecStart = "${beefweb-mpris}/bin/beefweb_mpris";
      Restart = "on-failure";
    };
  };
}