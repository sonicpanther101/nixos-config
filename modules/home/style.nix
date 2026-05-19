{ ... } : {
  catppuccin = {
    enable = true;
    accent = "blue";
    flavor = "mocha";

    vscode.profiles.default.enable = false;
    hyprlock.enable = false;
    btop.enable = false;
    hyprland.enable = false;
  };

  stylix = {
    targets = {
      hyprland.enable = false;
    };
  };
}