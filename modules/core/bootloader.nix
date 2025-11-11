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

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "desktop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

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
    inputs.erosanix.packages.x86_64-linux.foobar2000
    git
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
    format = "{:%a %d %b %H:%M}";
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