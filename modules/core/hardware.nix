{ host, pkgs-unstable, pkgs-stable, inputs, config, ... } : {

  hardware = {
    # Common settings
    enableRedistributableFirmware = true;
    
    graphics = {
      enable = true;
      enable32Bit = true;
      
      extraPackages = with pkgs-unstable; (if (host == "desktop") then [
        libva-vdpau-driver
        libvdpau-va-gl
        nvidia-vaapi-driver
      ] else if (host == "laptop") then [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        libvdpau-va-gl
        intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but sometimes more stable)
      ] else []);
      
      extraPackages32 = with pkgs-unstable.pkgsi686Linux; (if (host == "desktop") then [
        libva-vdpau-driver
        libvdpau-va-gl
      ] else []);
    } // (if (host == "desktop") then {
      # Use pkgs consistently for desktop
      package = pkgs-unstable.mesa;
      package32 = pkgs-unstable.pkgsi686Linux.mesa;
    } else {});

    bluetooth = {
      enable = true; # enables support for Bluetooth
      powerOnBoot = true;
    };

  } // (if (host == "desktop") then {
    # OpenRGB
    i2c.enable = true;

    # XBox controller
    xpadneo.enable = true;

    nvidia = {
      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
      # of just the bare essentials.
      powerManagement.enable = true;

      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = false;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of 
      # supported GPUs is at: 
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
      # Only available from driver 515.43.04+
      # Currently alpha-quality/buggy, so false is currently the recommended setting.
      open = true;

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  } else {});

  environment = {
    
    sessionVariables = {
      # If your cursor becomes invisible
      WLR_NO_HARDWARE_CURSORS = "1";
      # Hint electron apps to use wayland
      NIXOS_OZONE_WL = "1";
    } // (if (host == "laptop") then {
      # Intel-specific environment variables
      LIBVA_DRIVER_NAME = "iHD"; # or "i965" if iHD doesn't work
    } else {});

    pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

    systemPackages = if (host == "desktop") then [
      (pkgs-stable.callPackage ../../packages/openrgb.nix { })
    ] else [];
  };
}