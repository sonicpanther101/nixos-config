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

    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };

  services = {
    
    pulseaudio = {
      package = pkgs.pulseaudio.override { jackaudioSupport = true; };
    };

    blueman.enable = true;
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 59010 59011 ];
}
