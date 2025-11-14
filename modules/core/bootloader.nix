{ inputs, config, pkgs-unstable, pkgs-stable, lib, host, ... }:{

  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      useOSProber = false;
      memtest86.enable = true;
    };
  };
  boot.supportedFilesystems = [ "ntfs" ];

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Set your time zone.
  time.timeZone = "Pacific/Auckland";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_NZ.UTF-8";

  i18n.extraLocaleSettings = {
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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "nz";
    variant = "";
  };

  services.syncthing = {
    openDefaultPorts = true; # Open ports in the firewall for Syncthing. (NOTE: this will not open syncthing gui port)
  };
  # port 8384 is the default port to allow syncthing GUI access from the network.
  networking.firewall.allowedTCPPorts = [ 8384 ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.adam = {
    isNormalUser = true;
    description = "adam";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs-unstable; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs-unstable; [
    kitty
    os-prober
    vivaldi
    vscodium-fhs
    firefox
    kdePackages.dolphin
    grayjay
    bottles
    ghostty
    wofi
    resources
    htop
    inputs.erosanix.packages.x86_64-linux.foobar2000
  ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 10";
    flake = "/home/adam/nixos-config#desktop";
  };

  imports = [ inputs.home-manager.nixosModules.home-manager ];
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = [];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs host pkgs-stable; };
    users.adam = {
      programs.home-manager.enable = true;
      home.username = "adam";
      home.homeDirectory = "/home/adam";
      home.stateVersion = "25.05";

      programs.git = {
        enable = true;
        settings = {
          user = {
            name  = "sonicpanther101";
            email = "sonicpanther101@gmail.com";
          };
        };
      };

      services.syncthing = {
        enable = true;
        settings = {
          devices = {
            "Phone" = { id = "U3WDNWK-4BIUXM4-OS5SUHL-EZEFTWT-22NIYE6-QEZ6YS5-5WNR7QW-DYRUKAH"; };
          };
          folders = {
            "School" = {
              id = "r7hv7-6lau7";
              path = "/home/adam/driveBig/School/";
              devices = [ "Phone" ];
            };
          };
        };
      };

      programs.waybar = {
        enable = true;
        settings = {
mainBar = {
  layer = "bottom";
  position = "top";
  height = 30;

  modules-left = ["hyprland/workspaces"];
  modules-center = ["clock"];
  modules-right = ["tray" "backlight" "pulseaudio" "network" "idle_inhibitor" "battery"];

  "hyprland/workspaces" = {
    format = "<sub>{icon}</sub>\n{windows}";
    format-window-separator = "\n";
    window-rewrite-default = "";
    window-rewrite = {
      # title<.*youtube.*> = ""; # Windows whose titles contain "youtube"
      # class<firefox> = ""; # Windows whose classes are "firefox"
      # class<firefox> title<.*github.*> = ""; # Windows whose class is "firefox" and title contains "github". Note that "class" always comes first.
      foot = ""; # Windows that contain "foot" in either class or title. For optimization reasons, it will only match against a title if at least one other window explicitly matches against a title.
      code = "󰨞";
    };
  };
  
  clock = {
    format = "{:%a %d %b %I:%M%p}";
    tooltip = false;
  };
  
  network = {
    format = "{icon}";
    format-alt = "{ipaddr}/{cidr} {icon}";
    format-alt-click = "click-right";
    format-icons = {
      wifi = ["" "" ""];
      ethernet = [""];
      disconnected = [""];
    };
    on-click = "termite -e nmtui";
    tooltip = false;
  };
  
  pulseaudio = {
    format = "{icon}";
    format-alt = "{volume} {icon}";
    format-alt-click = "click-right";
    format-muted = "";
    format-icons = {
      phone = [" " " " " " " "];
      default = ["" "" "" ""];
    };
    scroll-step = 10;
    on-click = "pavucontrol";
    tooltip = false;
  };
  
  backlight = {
    format = "{icon}";
    format-alt = "{percent}% {icon}";
    format-alt-click = "click-right";
    format-icons = ["" ""];
    on-scroll-down = "light -A 1";
    on-scroll-up = "light -U 1";
  };
  
  idle_inhibitor = {
    format = "{icon}";
    format-icons = {
      activated = "";
      deactivated = "";
    };
    tooltip = false;
  };
  
  tray = {
    icon-size = 18;
  };
};
        };
        style = ''
* {
    border:        none;
    border-radius: 0;
    font-family:   Sans;
    font-size:     15px;
    box-shadow:    none;
    text-shadow:   none;
    transition-duration: 0s;
}

window {
    color:      rgba(217, 216, 216, 1);
    background: rgba(35, 31, 32, 0.00);
}

window#waybar.solo {
    color:      rgba(217, 216, 216, 1);
    background: rgba(35, 31, 32, 0.85);
}

#workspaces {
    margin: 0 5px;
}

#workspaces button {
    padding:    0 5px;
    color:      rgba(217, 216, 216, 0.4);
}

#workspaces button.visible {
    color:      rgba(217, 216, 216, 1);
}

#workspaces button.focused {
    border-top: 3px solid rgba(217, 216, 216, 1);
    border-bottom: 3px solid rgba(217, 216, 216, 0);
}

#workspaces button.urgent {
    color:      rgba(238, 46, 36, 1);
}

#mode, #battery, #cpu, #memory, #network, #pulseaudio, #idle_inhibitor, #backlight, #custom-storage, #custom-spotify, #custom-weather, #custom-mail {
    margin:     0px 6px 0px 10px;
    min-width:  25px;
}

#clock {
    margin:     0px 16px 0px 10px;
    min-width:  140px;
}

#battery.warning {
   color:       rgba(255, 210, 4, 1);
}

#battery.critical {
    color:      rgba(238, 46, 36, 1);
}

#battery.charging {
    color:      rgba(217, 216, 216, 1);
}

#custom-storage.warning {
    color:      rgba(255, 210, 4, 1);
}

#custom-storage.critical {
    color:      rgba(238, 46, 36, 1);
}
        '';
      };
    };
  };


  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
	  # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.sessionVariables = {
    # If your cursor becomes invisible
    WLR_NO_HARDWARE_CURSORS = "1";
    # Hint electron apps to use wayland
    NIXOS_OZONE_WL = "1";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}