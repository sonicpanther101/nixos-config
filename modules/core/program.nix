{ pkgs, inputs, host, ... }: 
{
  programs.dconf.enable = true;
  programs.zsh.enable = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = if (host == "desktop") then
      inputs.hyprland-desktop.packages.${pkgs.stdenv.hostPlatform.system}.hyprland
    else
      inputs.hyprland-laptop.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
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
    enable = false;
    binfmt = true;
    package = pkgs.appimage-run.override {
      # extraPkgs = pkgs: [ pkgs.ffmpeg pkgs.imagemagick ];
    };
  };
}