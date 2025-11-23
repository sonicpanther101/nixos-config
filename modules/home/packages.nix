{ inputs, pkgs-unstable, pkgs-stable, ... } : {

  home.packages = with pkgs-unstable; [ # Packages to be updated often            

    vivaldi                             # Browser                                 
    vscodium-fhs                        # Code editor                             
    grayjay                             # Youtube frontend                        
    bottles                             # Windows emulater                        
                                       
  ] ++ (with pkgs-stable; [             # Packages that dont need to be up to date

    corefonts                           # Fonts so that none are missing          
    noto-fonts                         
    noto-fonts-cjk-sans                 # Chinese, Japanese and Korean glyphs     
    noto-fonts-emoji                   
    noto-fonts-extra                   
    ipafont                            

    waybar-mpris                        # To show music on bar                    
    wofi                                # App launcher                            
    resources                           # Graphical resource manager              
    htop                                # Resource manager                        
    playerctl                           # To control media from cli               
    pamixer                             # Pulseaudio command line mixer           
    p7zip                               # For unzipping                           
    unrar                               # For unzipping multi part rars           
    tree                                # Show file structure (somehow missing)   
    nemo-with-extensions                # File browser                            
    adwaita-icon-theme                  # Themes icons in nemo                    
    os-prober                           # To add other os' to grub                
    vlc                                 # Video player                            
    copyq                               # Clipboard manager
    
  ]) ++ (if (host == "destop") then [

  ] else [

  ]);
}