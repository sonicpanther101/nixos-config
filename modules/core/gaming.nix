{ ... } : {

  # Steam with optimizations
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };
  
  programs.gamemode.enable = true; # Performance mode
}