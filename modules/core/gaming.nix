{ pkgs-stable, ... } : {

  # Steam with optimizations
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };
  
  programs.gamemode.enable = true; # Performance mode

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs-stable; [
      stdenv.cc.cc.lib
      zlib openssl curl expat
      vulkan-loader libGL
      icu libxml2 libxcrypt
      gamemode
    ];
  };
}
