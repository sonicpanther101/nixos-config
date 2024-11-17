{pkgs, ...}: let
  my-install = pkgs.writeShellScriptBin "my-install" (builtins.readFile ./scripts/my-install.sh);
  my-shutdown = pkgs.writeShellScriptBin "my-shutdown" (builtins.readFile ./scripts/my-shutdown.sh);
  my-sleep = pkgs.writeShellScriptBin "my-sleep" (builtins.readFile ./scripts/my-sleep.sh);
  my-clean = pkgs.writeShellScriptBin "my-clean" (builtins.readFile ./scripts/my-clean.sh);
  my-tachidesk = pkgs.writeShellScriptBin "my-tachidesk" (builtins.readFile ./scripts/my-tachidesk.sh);
  my-linewize = pkgs.writeShellScriptBin "my-linewize" (builtins.readFile ./scripts/my-linewize.sh);
  my-ags = pkgs.writeShellScriptBin "my-ags" (builtins.readFile ./scripts/my-ags.sh);
  my-update = pkgs.writeShellScriptBin "my-update" (builtins.readFile ./scripts/my-update.sh);
  my-rwall = pkgs.writeShellScriptBin "my-rwall" (builtins.readFile ./scripts/my-rwall.sh);
  # wall-change = pkgs.writeShellScriptBin "wall-change" (builtins.readFile ./scripts/wall-change.sh);
  # wallpaper-picker = pkgs.writeShellScriptBin "wallpaper-picker" (builtins.readFile ./scripts/wallpaper-picker.sh);
  
  # runbg = pkgs.writeShellScriptBin "runbg" (builtins.readFile ./scripts/runbg.sh);
  # music = pkgs.writeShellScriptBin "music" (builtins.readFile ./scripts/music.sh);
  # lofi = pkgs.writeScriptBin "lofi" (builtins.readFile ./scripts/lofi.sh);
  
  # toggle_blur = pkgs.writeScriptBin "toggle_blur" (builtins.readFile ./scripts/toggle_blur.sh);
  # toggle_oppacity = pkgs.writeScriptBin "toggle_oppacity" (builtins.readFile ./scripts/toggle_oppacity.sh);
  
  maxfetch = pkgs.writeScriptBin "maxfetch" (builtins.readFile ./scripts/maxfetch.sh);
  
  # compress = pkgs.writeScriptBin "compress" (builtins.readFile ./scripts/compress.sh);
  # extract = pkgs.writeScriptBin "extract" (builtins.readFile ./scripts/extract.sh);
  
  # shutdown-script = pkgs.writeScriptBin "shutdown-script" (builtins.readFile ./scripts/shutdown-script.sh);
  
  # show-keybinds = pkgs.writeScriptBin "show-keybinds" (builtins.readFile ./scripts/keybinds.sh);
  
  # vm-start = pkgs.writeScriptBin "vm-start" (builtins.readFile ./scripts/vm-start.sh);

  # ascii = pkgs.writeScriptBin "ascii" (builtins.readFile ./scripts/ascii.sh);
in {
  home.packages = with pkgs; [
    my-install
    my-shutdown
    my-sleep
    my-clean
    my-tachidesk
    my-linewize
    my-ags
    my-update
    my-rwall
    # wall-change
    # wallpaper-picker
    
    
    # runbg
    # music
    # lofi
  
    # toggle_blur
    # toggle_oppacity

    maxfetch

    # compress
    # extract

    # shutdown-script
    
    # show-keybinds

    # vm-start

    # ascii
  ];
}
