{ pkgs-stable, ... } :  {
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    package = pkgs-stable.pipewire;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    # lowLatency.enable = true;

    # For screen sharing
    wireplumber = {
      enable = true;
      package = pkgs-stable.wireplumber;
    };
  };
}