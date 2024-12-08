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
      powerOnBoot = false;
    };
  };

  services.blueman.enable = true;

  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = null;
      PermitRootLogin = "yes";
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 59010 59011 ];
}
