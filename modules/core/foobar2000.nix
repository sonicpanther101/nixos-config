{ pkgs, lib, config, pkgs-stable, inputs, username, ... }:

let
  # This tells beefweb to launch 'foobar2000'
  foobarPkg = inputs.erosanix.packages.${pkgs-stable.system}.foobar2000;
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

  foobar2000Original = inputs.erosanix.packages.${pkgs-stable.system}.foobar2000;

  foobar2000 = foobar2000Original.overrideAttrs (oldAttrs: {
    # Append to the existing winAppInstall script
    winAppInstall = ''
      ${oldAttrs.winAppInstall}

      # --- Start Dark Mode Fix ---
      # This is the command that sets a registry key in the Wine prefix
      # to enable Windows-level dark mode for applications that support it.
      # Foobar2000 v2 is known to support this.
      # Key: HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize
      # Value: AppsUseLightTheme (DWORD)
      # 0 = Dark Mode (what we want)
      # 1 = Light Mode
      $WINE reg add 'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' /v 'AppsUseLightTheme' /t REG_DWORD /d 0 /f
      # --- End Dark Mode Fix ---
    '';
    
    # You might also want to change the name to distinguish it easily
    pname = "foobar2000";
  });

in {
  environment.systemPackages = [
    foobar2000
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