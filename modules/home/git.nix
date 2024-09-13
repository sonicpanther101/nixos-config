{ pkgs, ... }: 
{
  programs.git = {
    enable = true;
    
    userName = "sonicpanther101";
    userEmail = "sonicpanther101@gmail.com";
    
    extraConfig = { 
      init.defaultBranch = "main";
      credential.helper = "store";
    };
  };

  # home.packages = [ pkgs.gh pkgs.git-lfs ];
}
