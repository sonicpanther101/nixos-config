{ ... }: 
{
  programs = {
    git = {
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

    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        line-numbers = true;
        paging = "never";
        side-by-side = true;  # Optional: split view
      };
    };
  };
}