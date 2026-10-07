{ pkgs-stable, inputs, username, ... } :  {
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

  # Foobar2000 + MPRIS bridge.
  #
  # beefweb_mpris launches foobar2000 itself (foobar2000-command in its
  # config.yaml), waits for it, and exits cleanly when foobar2000 is closed
  # (e.g. Super+Q). So this unit "is" foobar2000: closing the app stops the
  # service, and `systemctl --user start foobar-mpris` (what the walker
  # desktop entry runs) brings it back.
  #
  # Previously it was launched through Hyprland's exec_cmd, which wraps it in
  # an unmanaged run-pNNN.scope. At shutdown that scope sat there for the full
  # 90s default stop timeout before being killed, stalling the whole reboot.
  systemd.user.services.foobar-mpris = {
    description = "Foobar2000 MPRIS bridge";
    # Started from Hyprland's autostart and from the walker entry, not
    # wantedBy anything: it needs the Wayland/X env, and must not be
    # respawned after the user deliberately closes it.
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    path = [ "/run/current-system/sw" "/etc/profiles/per-user/${username}" ];
    serviceConfig = {
      ExecStart = "${pkgs-stable.callPackage ../../packages/foobar2000.nix { inherit pkgs-stable inputs username; }}/bin/beefweb_mpris";
      # Kill foobar2000/wine (same cgroup) quickly at logout/shutdown.
      TimeoutStopSec = "10s";
    };
  };
}
