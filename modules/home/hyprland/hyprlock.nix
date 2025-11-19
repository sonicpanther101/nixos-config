{ ... } : {
  programs.hyprlock = {
    enable = true;
    settings = {
      pam.enabled = true;
    }
  }
}