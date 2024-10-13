{ pkgs, config, inputs, ... }: 
{
  home.packages = with pkgs;[
    ## Utils
    # gamemode
    # gamescope
    # winetricks
    # inputs.nix-gaming.packages.${pkgs.system}.wine-ge

    ## Cli games
    tcl2048
    bastet
    nethack
    nethack-qt
    nethack-x11
    ninvaders
    njam
    nsnake
    nudoku
    dwarf-fortress
    pong3d
    solitaire-tui
    dhewm3
    xlife
    bsdgames
    gltron
    veloren
    
    ## Celeste
    celeste-classic
    celeste-classic-pm

    ## Doom
    # gzdoom
    # crispy-doom

    ## Emulation
    # sameboy
    # snes9x
    # cemu
    # dolphin-emu
  ];
}
