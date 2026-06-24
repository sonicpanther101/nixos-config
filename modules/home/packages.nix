{ inputs, pkgs-unstable, pkgs-stable, isHighPower, ... } : {

  home.packages = [                                       # From inputs
    inputs.hyprshutdown.packages.${pkgs-stable.stdenv.hostPlatform.system}.default # For smooth shutdown of apps  # wait for nixos release
  ] ++ (with pkgs-unstable; [                             # Unstable packages (frequently updated packages)

    vsce                                                  # VS Code Extension Manager
    prusa-slicer                                          # Slicing software
    awww                                                  # Efficient animated wallpaper daemon for wayland, controlled at runtime

  ]) ++ (with pkgs-stable; [                              # Stable packages (less frequently updated)
                                                          # Fonts
    corefonts
    noto-fonts
    noto-fonts-cjk-sans                                   # Chinese, Japanese and Korean glyphs
    noto-fonts-color-emoji
    ipafont                                               # Japanese font set

                                                          # QT theming / styling
    libsForQt5.qt5ct                                      # Qt5 configuration tool
    libsForQt5.qtstyleplugin-kvantum                      # Kvantum theming engine (Qt5)
    kdePackages.qt6ct                                     # Qt6 configuration tool
    kdePackages.qtstyleplugin-kvantum                     # Kvantum theming engine (Qt6)

                                                          # Gaming tools (some may be unecessary)
    mangohud                                              # FPS/performance overlay
    protonplus                                            # Simple Wine and Proton-based compatibility tools manager
    heroic                                                # Epic/GOG games
    lutris                                                # Multi-launcher
    prismlauncher                                         # Minecraft launcher
    (bottles.override { removeWarningPopup = true; })     # Windows emulater, Wine prefix manager

                                                          # System tools / Utilities
                                                          # Wayland / launcher / compositor integrations
    waybar-mpris                                          # To show music on bar
    hyprsysteminfo                                        # Displays information about the running system
    hyprpolkitagent                                       # Required for GUI applications to be able to sudo
    hyprpicker                                            # Colour picker
    hyprmon                                               # TUI monitor configuration tool for Hyprland with visual layout and drag-and-drop
    wev                                                   # Wayland input watcher
    grim                                                  # Grab images from a Wayland compositor
    slurp                                                 # Select a region in a Wayland compositor
                                                          # File managers, icons & visual disk tools
    nemo-with-extensions                                  # File browser
    nemo-preview                                          # File previewer for Nemo
    qdirstat                                              # Visual file-system viewer like WizTree
                                                          # System monitoring & quick utilities
    fastfetch                                             # Actively maintained, feature-rich and performance oriented, neofetch like system information tool
    onefetch                                              # Git repository summary on your terminal
    eza                                                   # Replacement for ls
    jq                                                    # CL JSON interpreter
    usbutils                                              # Lists connected USB devices
    bitwise                                               # CLI tool for bit / hex manipulation
    file                                                  # Show file information
    wine                                                  # Windows emulator
    tesseract                                             # OCR engine
    gtrash                                                # rm replacement, put deleted files in system trash
    nix-prefetch-git                                      # Prefetches github things for nix
    nix-index                                             # For pay-respects to find packages
    nix-search-cli                                        # For pay-respects to find packages
    ripgrep                                               # Grep replacement
    gh                                                    # GitHub CLI tool
    bc                                                    # GNU software calculator
    wtype                                                 # Fake keyboard input (for pasting from clipboard manager)
    wakatime-cli                                          # WakaTime command line interface
    xeyes                                                 # If the eyes move the app is running on xwayland
    texliveMedium                                         # LaTeX packages
    typst                                                 # New markup-based typesetting system that is powerful and easy to learn
    efibootmgr                                            # Linux user-space application to modify the Intel Extensible Firmware Interface (EFI) Boot Manager
                                                          # Archives / compression
    p7zip                                                 # Unzip utility
    unrar                                                 # For unzipping multi-part RARs
                                                          # Desktop integration & trays
    networkmanagerapplet                                  # Tray GUI for NetworkManager
    nextdns                                               # For toggling DoH on/off
    libnotify                                             # Notification daemon (duplicate, but needed for install script)
    wvkbd                                                 # Onscreen touch keyboard
                                                          # Misc
    os-prober                                             # Detect other OSes for GRUB
    ventoy-full-gtk                                       # To set up drives to be bootable while still carrying files
                                                          # Media tools
    rnote                                                 # Simple drawing application to create handwritten notes
    pinta                                                 # Lightweight image editor
    handbrake                                             # FFMPEG GUI
    vlc                                                   # Video player
    imv                                                   # Image viewer
    mpv                                                   # Minimal video player
    ffmpeg                                                # CLI image/video editor
    wf-recorder                                           # Screen recorder
    grimblast                                             # Screenshot taker
    obs-studio                                            # Free and open source software for video recording and live streaming

                                                          # Audio tools
    (pkgs-stable.callPackage ../../packages/foobar2000.nix { inherit pkgs-stable inputs username; })
    cmus                                                  # Small, fast and powerful console music player for Linux
    cmusfm                                                # Last.fm and Libre.fm standalone scrobbler for the cmus music player
    playerctl                                             # To control media from cli
    pamixer                                               # Pulseaudio command line mixer
    crosspipe                                             # Audio connection editor
    pwvucontrol                                           # Audio device volume editor
    sox                                                   # Tone generator

                                                          # Clipboard tools
    wl-clipboard                                          # Clipboard utils for wayland (wl-copy, wl-paste)
    wl-clip-persist                                       # Keep clipboard contents after app closes

                                                          # Networking / P2P tools
    proton-vpn                                            # VPN
    qbittorrent                                           # Torrenting GUI
    nicotine-plus                                         # Soulseek peer to peer browser frontend

                                                          # Misc
    qalculate-qt                                          # Calculator app
    thunderbird                                           # Calendar and tasks app
    zeal                                                  # Simple offline API documentation browser
    cmatrix                                               # Matrix simulator
    cbonsai                                               # Bonsai generator
    vim-full                                              # Basic TUI code editor with tutorial
    catppuccinifier-gui                                   # Turns images into catppuccin only colours
    palettum                                              # CLI tool that lets you recolor images, GIFs and videos
    toipe                                                 # Typing test in the terminal
    gperftools                                            # Fast, multi-threaded malloc() and nifty performance analysis tools
    python314                                             # Latest release of python
    nixd                                                  # Feature-rich Nix language server interoperating with C++ nix
    libreoffice                                           # Comprehensive, professional-quality productivity suite, a variant of openoffice.org
    anki-bin                                              # Flashcards app
    moonlight-qt                                          # Remote desktop interface to go with the sunshine service

  ]) ++ (if isHighPower then (with pkgs-stable; [ # Host-specific additions
    ddcutil                                               # Desktop brighness controller
    freecad                                               # 3D Print designing software
    blender                                               # 3D modelling software
    (pkgs-stable.callPackage ../../packages/openrgb.nix { })
    (pkgs-stable.callPackage ../../packages/tagscanner.nix { inherit pkgs-stable inputs; })
    (pkgs-stable.callPackage ../../packages/mp3tag.nix { inherit pkgs-stable inputs; })
  ]) else (with pkgs-stable; [
    brightnessctl                                         # Laptop brighness controller
    poweralertd                                           # UPower-powered power alerter
    xournalpp                                             # Note taking and pdf annotating app
    resources                                             # Graphical resource manager
    wakeonlan                                             # wakeonlan -i <ip> <target_mac_address (74:56:3c:74:e3:8a for desktop)>
    (pkgs-stable.callPackage ../../packages/namida.nix { })
  ]));
}
