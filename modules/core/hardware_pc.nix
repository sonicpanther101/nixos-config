{ pkgs, ... }:
{  
  hardware = {
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        nvidia-vaapi-driver
      ];
    };

    pulseaudio = {
      package = pkgs.pulseaudio.override { jackaudioSupport = true; };
    };

    bluetooth = {
      enable = true;
      # powerOnBoot = true;
    };
  };

  services.blueman.enable = true;
}
