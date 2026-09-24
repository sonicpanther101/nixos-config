{ pkgs-stable, username, ... } :  {
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

  systemd.user.services.pipewire.wantedBy = [ "graphical-session.target" ];
  systemd.user.services.pipewire-pulse.wantedBy = [ "graphical-session.target" ];
  systemd.user.services.wireplumber.wantedBy = [ "graphical-session.target" ];

  # The *services* above were already declared, so Nix owned and refreshed
  # their enablement symlinks on every switch. The *sockets* were not
  # declared anywhere, so their enablement came from PipeWire's own
  # one-off vendor preset (applied once, at first login) rather than from
  # Nix. Because nothing in this config ever touched them again, they kept
  # pointing at whatever store path existed the day they were enabled —
  # and went dangling the moment that generation got garbage collected.
  # Declaring them here makes Nix own + refresh them on every switch too.
  systemd.user.sockets.pipewire.wantedBy = [ "sockets.target" ];
  systemd.user.sockets.pipewire-pulse.wantedBy = [ "sockets.target" ];

  # Safety net for the general class of bug, not just PipeWire: any other
  # package's systemd preset (wireplumber, xdg-desktop-portal, etc.) could
  # leave similar un-Nix-managed symlinks under ~/.config/systemd/user that
  # later rot when GC'd. Prune anything dangling on every switch so a stale
  # symlink can never silently sit there again — it'll either get cleanly
  # removed here, or get re-created correctly by the activation step above.
  system.activationScripts.pruneStaleUserSystemdUnits = {
    text = ''
      if [ -d "/home/${username}/.config/systemd/user" ]; then
        find "/home/${username}/.config/systemd/user" -xtype l -delete || true
      fi
    '';
    deps = [ "users" ];
  }; 

  # Foobar2000
  systemd.user.services.foobar-mpris = {
    description = "Foobar2000 MPRIS bridge";
    serviceConfig = {
      ExecStart = "beefweb_mpris";
      Restart = "on-failure";
    };
  };
}
