{ isDualBoot, lib, host, ...}: 
let
  dualBootId = "0004";
in {                              
  programs.zsh = {                                                         
    enable = true; 

    enableCompletion = true;                                               
    autosuggestion.enable = true;                                          
    syntaxHighlighting.enable = true; 

    oh-my-zsh = {                                                          
      enable = true;                                                       
      plugins = [ "git" "fzf" ];                                           
    };

    initContent = lib.mkBefore ''                                          
      DISABLE_MAGIC_FUNCTIONS=true
      eval "$(pay-respects zsh)"
    '';  

    shellAliases = {                                                       
                                                                            # Utils
      c = "clear";                                                         
      cd = "z";                                                             # uses zoxide
      tt = "gtrash put";                                                    # Trash files safely instead of rm
      cat = "bat";                                                          # Syntax-highlighted file viewer
      code = "codium";                                                     
      py = "python";                                                       
      icat = "kitten icat";                                                 # Kitty terminal image viewer
      dsize = "du -hs";                                                     # Show directory size in human-readable format
      psize = "df";                                                         # Show partition size in human-readable format
      findw = "grep -rl";                                                   # Search for text within files recursively
      l = "eza --icons  -a --group-directories-first -1";                   # List files with icons, including hidden, directories first
      ll = "eza --icons  -a --group-directories-first -1 --no-user --long"; # Same as l but with detailed info (no username shown)
      tree = "eza --icons --tree --group-directories-first";                # Display directory structure as a tree with icons

      nix-shell = "nix-shell --run zsh";                                    # Enter nix-shell with Zsh (instead of default bash)
      nix-develop = "nix develop -c $SHELL";                                # Enter nix develop with Zsh (instead of default bash)

                                                                            # python
      piv = "python -m venv .venv";                                         # Create virtual environment in .venv
      psv = "source .venv/bin/activate";                                    # Activate the virtual environment
      
      network-restart = "_ systemctl restart NetworkManager.service";       # Restarts the network manager, for when wifi is acting up
      zsh-reload = "rm ~/.zcompdump*";                                      # Reloads zsh autocomplete
      
      winboot = lib.mkIf isDualBoot "sudo efibootmgr -n ${dualBootId} && reboot";    # reboot into windows one time

      usb = "sudo mount -o gid=users,fmask=113,dmask=002 /dev/sdb1 ~/driveUSB"; # Mount an external usb drive, only works if one sd is already connected
    };

    # Autostart hyprland on boot
    loginExtra = ''
      if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec Hyprland
      fi
    '';                                                                      
  };                                                                       

  programs.zoxide = {                                                       # Smart cd replacement - jumps to frequently-used directories by typing partial names
    enable = true;                                                         
    enableZshIntegration = true;                                           
  };                                                                       

  programs.fzf = {                                                          # Fuzzy Finder search files, history, and commands with partial/misspelled matches
    enable = true;                                                         
    enableZshIntegration = true;                                           
  };                                                                
}