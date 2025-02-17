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
  };

  services = {    
    pulseaudio = {
      package = pkgs.pulseaudio.override { jackaudioSupport = true; };
    };

    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };

  services.blueman.enable = true;

  networking.firewall.allowedTCPPorts = [ 22 80 443 59010 59011 ];
}
