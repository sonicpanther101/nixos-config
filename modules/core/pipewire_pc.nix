{ pkgs, username, ... }: 
{
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # lowLatency.enable = true;
  };
  environment.systemPackages = with pkgs; [
    pulseaudioFull
  ];

  services.jack = {
    jackd.enable = true;
    # support ALSA only programs via ALSA JACK PCM plugin
    alsa.enable = true;
    # support ALSA only programs via loopback device (supports programs like Steam)
    loopback = {
      enable = false;
      # buffering parameters for dmix device to work with ALSA only semi-professional sound programs
      #dmixConfig = ''
      #  period_size 2048
      #'';
    };
  };

  users.extraUsers.${username}.extraGroups = [ "jackaudio" ];

  boot.kernelModules = [ "snd-seq" "snd-rawmidi" ];

  hardware.pulseaudio.package = pkgs.pulseaudio.override { jackaudioSupport = true; };
}
