{ pkgs, config, lib, ... }:

{
  services = {
    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;
    dbus.enable = true;
    fstrim.enable = true;
  };
  services.logind.extraConfig = ''
    # don’t shutdown when power button is short-pressed
    HandlePowerKey=ignore
  '';

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
  };
  services = {
    udev.packages = with pkgs; [ 
      openrgb-with-all-plugins
    ];
  };
  hardware.i2c.enable = true;
  hardware.i2c.group = "adam";
  environment.systemPackages = [ pkgs.i2c-tools ];
  users.groups.i2c.members = [ "adam" ];
  boot.kernelModules = [ "i2c-dev" "i2c-piix4" ];

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

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = false;

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
