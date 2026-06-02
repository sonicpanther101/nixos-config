{ host, pkgs-unstable, pkgs-stable, config, lib, ... } : {

  hardware = lib.mkMerge [{
    # Common settings
    enableRedistributableFirmware = true;
    
    graphics = lib.mkMerge [{
      enable = true;
      enable32Bit = true;
      
      extraPackages = (with pkgs-unstable;
        lib.optionals config.my.hasNvidia [
          libva-vdpau-driver
          libvdpau-va-gl
          nvidia-vaapi-driver
        ]
      ) ++ (with pkgs-unstable; lib.optionals (host == "laptop") [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        libvdpau-va-gl
        intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but sometimes more stable)
      ]);
      
      extraPackages32 = with pkgs-unstable.pkgsi686Linux;lib.optionals config.my.hasNvidia [
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    } (lib.mkIf config.my.hasNvidia {
      # Use pkgs consistently for desktop
      package = pkgs-unstable.mesa;
      package32 = pkgs-unstable.pkgsi686Linux.mesa;
    })];

    bluetooth = {
      enable = true; # enables support for Bluetooth
      powerOnBoot = true;
    };

  } (lib.mkIf config.my.hasNvidia {

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
  }) (lib.mkIf config.my.isHighPower {
    # OpenRGB
    i2c.enable = true;

    # XBox controller
    xpadneo.enable = true;
  }) (if (host == "laptop") then {
    microsoft-surface.kernelVersion = "stable";
  } else {})];

  environment = {
    
    sessionVariables = {
      # If your cursor becomes invisible
      WLR_NO_HARDWARE_CURSORS = "1";
      # Hint electron apps to use wayland
      NIXOS_OZONE_WL = "1";
    } // lib.optionalAttrs (host == "laptop") {
      # Intel-specific environment variables
      LIBVA_DRIVER_NAME = "iHD"; # or "i965" if iHD doesn't work
    };

    pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];
  };
}