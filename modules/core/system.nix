{ lib, username, ... } : {

  options.my = {
    isLaptop    = lib.mkOption { type = lib.types.bool; default = false; description = "Whether this machine is a laptop."; };
    hasNvidia   = lib.mkOption { type = lib.types.bool; default = false; description = "Whether this machine has an Nvidia GPU."; };
    isHighPower = lib.mkOption { type = lib.types.bool; default = false; description = "Whether this machine has high CPU/GPU resources."; };
    isDualBoot  = lib.mkOption { type = lib.types.bool; default = false; description = "Whether this machine has other operating systems."; };

    hasPinLogin = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether the hyprlock screen shows a numeric keypad instead of a password field.
        The keypad's presses are tracked entirely by the my-hyprlock-pin script (no PAM
        involved); a correct PIN just pkills hyprlock to dismiss it. There is no password
        fallback in this mode -- keep a TTY/SSH escape hatch handy in case the keypad
        misbehaves.
      '';
    };
    pinLoginCode = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Base64-encoded PIN accepted by the lock screen's keypad when hasPinLogin is true.
        This is obfuscation, not encryption -- anyone with read access to this config (or
        the built system) can trivially decode it. Generate with: printf '%s' "1234" | base64
      '';
    };
    pinLoginLength = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = "Number of digits in pinLoginCode. Must match exactly, or the keypad will submit too early/late.";
    };
  };

  config = {
    nix.settings = {

      experimental-features = [ "nix-command" "flakes" ];

      substituters = [
        "https://cache.nixos.org"
        "https://home-manager.cachix.org"
        "https://nix-community.cachix.org"
        "https://nyx-cache.chaotic.cx/"
        "https://nur.cachix.org"
        "https://hyprland.cachix.org"
        "https://catppuccin.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "home-manager.cachix.org-1:wLVmpPs9J1Na6uhEkqcJcdSmPR61rd76jOnlps6zvM8="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
        "nur.cachix.org-1:Wf8j2K7aJRYsse0vq1w4/4xqZLNlGLLaQKk0P8LgQME="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
        "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
        "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="
      ];

      trusted-users = [ username ];
    };

    nixpkgs.config = {
      # Allow unfree packages for the 4th time! Scrap that, they will soon depricate home manager allowing unfree
      allowUnfree = true;
    };

    # Set your time zone.
    time.timeZone = "Pacific/Auckland";

    # Select internationalisation properties.
    i18n = {
      defaultLocale = "en_NZ.UTF-8";

      extraLocaleSettings = {
        LC_ADDRESS = "en_NZ.UTF-8";
        LC_IDENTIFICATION = "en_NZ.UTF-8";
        LC_MEASUREMENT = "en_NZ.UTF-8";
        LC_MONETARY = "en_NZ.UTF-8";
        LC_NAME = "en_NZ.UTF-8";
        LC_NUMERIC = "en_NZ.UTF-8";
        LC_PAPER = "en_NZ.UTF-8";
        LC_TELEPHONE = "en_NZ.UTF-8";
        LC_TIME = "en_NZ.UTF-8";
      };
    };

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    # programs.mtr.enable = true;
    # programs.gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
