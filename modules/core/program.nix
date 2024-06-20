{ pkgs, kaizen, ... }: 
{
  programs.dconf.enable = true;
  programs.zsh.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    # pinentryFlavor = "";
  };
  imports = [ kaizen.homeManagerModules.default; ]; 
  programs.kaizen = {
    enable = true;
  };
}
