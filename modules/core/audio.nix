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

  system.activationScripts.pipewireSanity = ''
    rm -f /home/*/.config/systemd/user/pipewire.service || true
    rm -f /home/*/.config/systemd/user/wireplumber.service || true
  '';

  # Foobar2000
  systemd.user.services.foobar-mpris = {
    description = "Foobar2000 MPRIS bridge";
    serviceConfig = {
      ExecStart = "beefweb_mpris";
      Restart = "on-failure";
    };
  };
}