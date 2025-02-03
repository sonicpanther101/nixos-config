{ pkgs, pkgs-stable, config, lib, username, ... }:
{
  services = {
    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;
    dbus.enable = true;
    fstrim.enable = true;
  };
  services.logind = {
    extraConfig = ''
      HandlePowerKey=suspend-then-hibernate
    '';
  };
  systemd.sleep.extraConfig = "HibernateDelaySec=2h";

  hardware.enableRedistributableFirmware = true;
  services.hardware.openrgb = {
    enable = false;
    package = lib.mkDefault pkgs-stable.openrgb-with-all-plugins;
  };
  boot.kernelParams = [ "acpi_enforce_resources=lax" "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
  boot.kernelModules = [ "i2c-dev" "i2c-piix4" ]; # "nouveau" ];
  users.groups.i2c.members = [ username ];

  services.udev.packages = with pkgs; [
    # qmk-udev-rules
  ];

  services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="1532", ATTRS{idProduct}=="00c5", ATTR{power/wakeup}="disabled"
      ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0361", ATTR{power/wakeup}="disabled"
      SUBSYSTEMS=="usb|hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0361", TAG+="uaccess", TAG+="Keychron V6"
    '';

  hardware.xpadneo.enable = true;

  hardware.bluetooth.settings = {
    General = {
      Privacy = "device";
      JustWorksRepairing = "always";
      Class = "0x000100";
      FastConnectable = true;
    };
  };

  boot = {
    extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];
    extraModprobeConfig = ''
      options bluetooth disable_ertm=Y
    '';
  };
  

  services.ollama = {
    #package = pkgs.unstable.ollama; # Uncomment if you want to use the unstable channel, see https://fictionbecomesfact.com/nixos-unstable-channel
    enable = true;
    acceleration = "cuda"; # Or "rocm"
    #environmentVariables = { # I haven't been able to get this to work myself yet, but I'm sharing it for the sake of completeness
      # HOME = "/home/ollama";
      # OLLAMA_MODELS = "/home/ollama/models";
      # OLLAMA_HOST = "0.0.0.0:11434"; # Make Ollama accesible outside of localhost
      # OLLAMA_ORIGINS = "http://localhost:8080,http://192.168.0.10:*"; # Allow access, otherwise Ollama returns 403 forbidden due to CORS
    #};
  };

  # # Blacklist the proprietary NVIDIA driver, if needed
  # boot.blacklistedKernelModules = [ "nvidia" "nvidia_uvm" "nvidia_drm" "nvidia_modeset" ];

  # # Configure Xorg to use the Nouveau driver
  # services.xserver = {
  #  enable = true;
  #  videoDrivers = [ "nouveau" ];

  #  # Optional: Configure display settings, if necessary
  #  # displayManager = {
  #  #   ...
  #  # };
  #  # desktopManager = {
  #  #   ...
  #  # };
  # };

  # Enable hardware acceleration for Nouveau
  # hardware.opengl = {
  #  enable = true;
  #  extraPackages = with pkgs; [
  #    # Add packages needed for Nouveau acceleration here
  #    # For example, Mesa for OpenGL:
  #    mesa
  #    mesa.drivers
  #  ];
  # };

  # # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {

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
    open = false;

    # Enable the Nvidia settings menu,
	  # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.sessionVariables = {
    # If your cursor becomes invisible
    WLR_NO_HARDWARE_CURSORS = "1";
    # Hint electron apps to use wayland
    NIXOS_OZONE_WL = "1";
  };

}
