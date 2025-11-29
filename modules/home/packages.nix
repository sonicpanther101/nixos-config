{ inputs, pkgs-unstable, pkgs-stable, host, ... } : {    

  home.packages = with pkgs-unstable; [                   # Packages to be updated often

    vscodium-fhs                                          # Code editor
    grayjay                                               # Youtube frontend
    (bottles.override { removeWarningPopup = true; })     # Windows emulater, Wine prefix manager
                                                         
  ] ++ (with pkgs-stable; [                               # Packages that dont need to be up to date

    corefonts                                             # Fonts so that none are missing
    noto-fonts                                           
    noto-fonts-cjk-sans                                   # Chinese, Japanese and Korean glyphs
    noto-fonts-emoji                                     
    noto-fonts-extra                                     
    ipafont                                              
                                                          # Gaming (some may be unecessary)
    mangohud                                              # FPS/performance overlay
    protonup-qt                                           # Manage custom Proton versions
    heroic                                                # Epic/GOG games
    lutris                                                # Multi-launcher
    prismlauncher                                         # Minecraft launcher

    waybar-mpris                                          # To show music on bar
    cava                                                  # Audio visualiser
    wofi                                                  # App launcher
    resources                                             # Graphical resource manager
    htop                                                  # Resource manager
    playerctl                                             # To control media from cli
    pamixer                                               # Pulseaudio command line mixer
    p7zip                                                 # For unzipping
    unrar                                                 # For unzipping multi part rars
    nemo-with-extensions                                  # File browser
    adwaita-icon-theme                                    # Themes icons in nemo
    os-prober                                             # To add other os' to grub
    vlc                                                   # Video player
    copyq                                                 # Clipboard manager
    hyprsome                                              # Hyprland extension to have monitor specific workspaces
    helvum                                                # Audio connection editor
    pwvucontrol                                           # Audio device volume editor
    nicotine-plus                                         # Soulseek peer to peer browser frontend
    qdirstat                                              # Visual file system veiwer like wiztree
    kooha                                                 # Screen recorder
    grimblast                                             # Screenshot taker
    libnotify                                             # For my-install notifications (I know it's a duplicate notification daemon)
    catppuccinifier-gui                                   # Turns images into catppuccin only colours
    imv                                                   # Image viewer
    mpv                                                   # Video viewer (simpler and more minimal than VLC)
    ffmpeg                                                # CLI image and video editor
    wl-clipboard                                          # Clipboard utils for wayland (wl-copy, wl-paste)
    cliphist                                              # Clipboard manager (duplicate of copyq)
    networkmanagerapplet                                  # Tray GUI for network manager

  ]) ++ (if (host == "desktop") then (with pkgs-stable; [
    ddcutil                                               # Desktop brighness controller
  ]) else if (host == "laptop") then (with pkgs-stable; [
    brightnessctl                                         # Laptop brighness controller
  ]) else [                                              
  ]);                                                    
}