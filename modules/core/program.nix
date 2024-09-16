{ pkgs, inputs, ... }: 
{
  programs.dconf.enable = true;
  programs.zsh.enable = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  };
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    # pinentryFlavor = "";
  };

  programs.direnv = {
    enable = true;
  };

  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      # extraPkgs = pkgs: [ pkgs.ffmpeg pkgs.imagemagick ];
    };
  };
}
