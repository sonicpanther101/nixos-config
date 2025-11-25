{ ... }: 
{
  programs.git = {
    enable = true;
    
    settings = {
      user = {
        name  = "sonicpanther101";
        email = "sonicpanther101@gmail.com";
      };

      init.defaultBranch = "main";
      credential.helper = "store";
    };
  };
}