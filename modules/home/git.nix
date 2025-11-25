{ ... }: 
{
  programs.git = {
    enable = true;
    
    settings = {
      user = {
        name  = "sonicpanther101";
        email = "sonicpanther101@gmail.com";
      };
    };
    
    extraConfig = { 
      init.defaultBranch = "main";
      credential.helper = "store";
    };
  };
}