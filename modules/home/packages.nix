{ inputs, pkgs, pkgs-stable, host, lib, ... }: 
{
  home.packages = (with pkgs; [
    kooha
    bootiso
    p7zip
    jq
    ddcutil
    nodejs_22
    wlsunset
    # nurl
    cowsay
    fortune
    cbonsai
    pipes
    neofetch
    bottles
    # spotify
    protonvpn-gui
    nh
    nvd
    # nix-output-monitor
    tor-browser
    suwayomi-server
    # tonelib-gfx
    i2c-tools
    usbutils
    qdirstat
    libinput
    iptsd
    lsof
    imagemagick
    resources
    htop
    btop
    qdirstat
    bun
    torrential
    vivaldi
    git
    #python310
    stdenv.cc.cc.lib
    stdenv.cc
    ncurses5
    binutils
    gitRepo gnupg autoconf curl
    procps gnumake util-linux m4 gperf unzip
    libGLU libGL
    #glib
    #glibc
    icu74

    bitwise                           # cli tool for bit / hex manipulation
    eza                               # ls replacement
    entr                              # perform action when file change
    fd                                # find replacement
    file                              # Show file information 
    fzf                               # fuzzy finder
    gtt                               # google translate TUI
    # gimp
    gtrash                            # rm replacement, put deleted files in system trash
    hexdump
    # jdk17                             # java
    lazygit
    # 
    nemo-with-extensions              # file manager
    nitch                             # systhem fetch util
    nix-prefetch-github
    (prismlauncher.override { jdks = [ jdk8 jdk17 jdk21 ]; })                     # minecraft launcher
    ripgrep                           # grep replacement
    # soundwireserver                   # pass audio to android phone
    todo                              # cli todo list
    toipe                             # typing test in the terminal
    valgrind                          # c memory analyzer
    yazi                              # terminal file manager
    zenity
    winetricks
    wineWowPackages.wayland

    # C / C++
    gcc
    gnumake

    # Python
    python313Full
    # python312Packages.pydantic
    # uv
    # mypy

    bleachbit                         # cache cleaner
    cmatrix
    gparted                           # partition manager
    ffmpeg
    imv                               # image viewer
    killall
    libnotify
    mpv                               # video player
    ncdu                              # disk space
    openssl
    pamixer                           # pulseaudio command line mixer
    pavucontrol                       # pulseaudio volume controle (GUI)
    playerctl                         # controller for media players
    wl-clipboard                      # clipboard utils for wayland (wl-copy, wl-paste)
    cliphist                          # clipboard manager
    poweralertd
    qalculate-gtk                     # calculator
    unzip
    wget
    xdg-utils
    imagemagick
    xxd
    inputs.alejandra.defaultPackage.${system}
    unrar-wrapper
    tor
    torsocks
  ] ++ lib.optionals (host == "desktop") [
    blender
    gamescope
    pyload-ng
    mangohud
    proteus
    qmk

    cudatoolkit
    linuxPackages.nvidia_x11
    xorg.libXi
    xorg.libXmu
    freeglut
    xorg.libXext
    xorg.libX11
    xorg.libXv
    xorg.libXrandr
    zlib
    # for xformers
    gcc
    gperftools
    gcc-unwrapped.lib
  ]) ++ (with pkgs-stable; [
    geekbench
    libreoffice
  ]);
}