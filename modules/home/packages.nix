{ inputs, pkgs-unstable, pkgs-stable, host, ... } : {

  home.packages = [ # From inputs
    inputs.hyprshutdown.packages.${pkgs-stable.stdenv.hostPlatform.system}.default # For smooth shutdown of apps  # wait for nixos release
  ] ++ (with pkgs-unstable; [                             # Unstable packages (frequently updated packages)

    vscodium-fhs                                          # Code editor
    vsce                                                  # VS Code Extension Manager
    grayjay                                               # Youtube frontend
    (bottles.override { removeWarningPopup = true; })     # Windows emulater, Wine prefix manager
    bambu-studio                                          # Slicing software

  ]) ++ (with pkgs-stable; [                               # Stable packages (less frequently updated)
                                                          # Fonts
    corefonts
    noto-fonts
    noto-fonts-cjk-sans                                   # Chinese, Japanese and Korean glyphs
    noto-fonts-emoji
    noto-fonts-extra
    ipafont                                               # Japanese font set

                                                          # QT theming / styling
    libsForQt5.qt5ct                                      # Qt5 configuration tool
    libsForQt5.qtstyleplugin-kvantum                      # Kvantum theming engine (Qt5)
    kdePackages.qt6ct                                     # Qt6 configuration tool
    kdePackages.qtstyleplugin-kvantum                     # Kvantum theming engine (Qt6)

                                                          # Gaming tools (some may be unecessary)
    mangohud                                              # FPS/performance overlay
    protonup-qt                                           # Manage custom Proton versions
    heroic                                                # Epic/GOG games
    lutris                                                # Multi-launcher
    prismlauncher                                         # Minecraft launcher

                                                          # System tools / Utilities
                                                          # Wayland / launcher / compositor integrations
    waybar-mpris                                          # To show music on bar
    hyprsome                                              # Hyprland extension to have monitor specific workspaces
    hyprsysteminfo                                        # Displays information about the running system
    hyprpolkitagent                                       # Required for GUI applications to be able to sudo
    wofi                                                  # App launcher
    wofi-emoji                                            # Wofi emoji picker
    hyprpicker                                            # Colour picker
    grim                                                  # Grab images from a Wayland compositor
    slurp                                                 # Select a region in a Wayland compositor
                                                          # File managers, icons & visual disk tools
    nemo-with-extensions                                  # File browser
    adwaita-icon-theme                                    # Icon theme for Nemo
    qdirstat                                              # Visual file-system viewer like WizTree
                                                          # System monitoring & quick utilities
    resources                                             # Graphical resource manager
    htop                                                  # Resource manager
    eza                                                   # Replacement for ls
    jq                                                    # CL JSON interpreter
    usbutils                                              # Lists connected USB devices
    bitwise                                               # CLI tool for bit / hex manipulation
    file                                                  # Show file information
    gtrash                                                # rm replacement, put deleted files in system trash
    nix-prefetch-github                                   # Prefetches github things for nix
    ripgrep                                               # Grep replacement
                                                          # Archives / compression
    p7zip                                                 # Unzip utility
    unrar                                                 # For unzipping multi-part RARs
                                                          # Desktop integration & trays
    networkmanagerapplet                                  # Tray GUI for NetworkManager
    libnotify                                             # Notification daemon (duplicate, but needed for install script)
                                                          # Misc
    os-prober                                             # Detect other OSes for GRUB
    # ventoy                                              # To set up drives to be bootable while still carrying files
                                                          # Media tools
    pinta                                                 # Lightweight image editor
    handbrake                                             # FFMPEG GUI
    vlc                                                   # Video player
    imv                                                   # Image viewer
    mpv                                                   # Minimal video player
    ffmpeg                                                # CLI image/video editor
    kooha                                                 # Screen recorder
    grimblast                                             # Screenshot taker

                                                          # Audio tools
    cava                                                  # Audio visualiser
    playerctl                                             # To control media from cli
    pamixer                                               # Pulseaudio command line mixer
    helvum                                                # Audio connection editor
    pwvucontrol                                           # Audio device volume editor

                                                          # Clipboard tools
    wl-clipboard                                          # Clipboard utils for wayland (wl-copy, wl-paste)
    copyq                                                 # Clipboard manager
    cliphist                                              # Clipboard manager (duplicate of copyq)

                                                          # Networking / P2P tools
    qbittorrent                                           # Torrenting GUI
    nicotine-plus                                         # Soulseek peer to peer browser frontend

                                                          # Misc
    cmatrix                                               # Matrix simulator
    neovim                                                # TUI code editor
    catppuccinifier-gui                                   # Turns images into catppuccin only colours
    toipe                                                 # Typing test in the terminal
    gperftools                                            # Fast, multi-threaded malloc() and nifty performance analysis tools
    python314                                             # Latest release of python

  ]) ++ (if (host == "desktop") then (with pkgs-stable; [ # Host-specific additions
    ddcutil                                               # Desktop brighness controller
    freecad                                               # 3D Print designing software
    blender                                               # 3D modelling software
    ollama                                                # Runs LLM's locally
  ]) else if (host == "laptop") then (with pkgs-stable; [
    brightnessctl                                         # Laptop brighness controller
  ]) else [
  ]);
}