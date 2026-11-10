{ host, lib, isLaptop, isServer, ... } :
let
  # Screen blanking (DPMS) is what used to crash Hyprland, so it goes through
  # `my-dpms` (deferred, staggered, circuit-breakered; see my-dpms.sh) and by
  # default only touches internal laptop panels. External DP/HDMI monitors that
  # deep-sleep when blanked trigger Hyprland 0.56/0.57 connector-reappear bugs.
  # Set this to true to also blank external monitors (e.g. on the desktop) -
  # my-dpms' breaker turns itself off if Hyprland ever dies while blanked.
  dpmsExternalOutputs = true;

  # laptop-2 has never had screen-off (see git history); left that way.
  hasDpms      = host != "laptop-2" && !isServer && (isLaptop || dpmsExternalOutputs);
  hasIdleLock  = host != "desktop";
  hasIdleSleep = host != "desktop" && !isServer;

  lockAfter = 600;
  # Blank AFTER the lock screen is up, never in the same moment as it.
  dpmsAfter = if hasIdleLock then lockAfter + 30 else 60;
  dpmsOff   = if dpmsExternalOutputs then "MY_DPMS_ALLOW='.*' my-dpms off" else "my-dpms off";
in {
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        # `start` is idempotent; `restart` would kill a live lock client.
        lock_cmd = "systemctl --user start hyprlock.service";
        # Holds the suspend inhibitor until Hyprland reports the session locked.
        before_sleep_cmd = "my-lock";
        after_sleep_cmd = "my-dpms on";
      };

      listener =
        lib.optionals hasIdleLock [
          {
            timeout = lockAfter;
            on-timeout = "systemctl --user start hyprlock.service";
          }
        ]
        ++ lib.optionals hasDpms [
          {
            timeout = dpmsAfter;
            on-timeout = dpmsOff;
            on-resume = "my-dpms on";
          }
        ]
        ++ lib.optionals hasIdleSleep [
          {
            timeout = 1800;
            on-timeout = "my-sleep";
          }
        ];
    };
  };
}
