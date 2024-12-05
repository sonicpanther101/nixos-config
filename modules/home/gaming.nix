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
    ninvaders
    nsnake
    dwarf-fortress
    pong3d
    solitaire-tui
    chess-tui
    # bsdgames
    # veloren
    
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