{ inputs, host, ... }: 
{
  imports = if (host == "desktop") then
         [ (import ./hyprland_end4.nix) ]
      #    [ (import ./hyprland.nix) ]
      # ++ [ (import ./config.nix) ]
      ++ [ (import ./variables.nix) ]
      ++ [ inputs.hyprland-desktop.homeManagerModules.default ]
    else 
         [ (import ./hyprland.nix) ]
      ++ [ (import ./config.nix) ]
      ++ [ (import ./variables.nix) ]
      ++ [ inputs.hyprland-laptop.homeManagerModules.default ]
    ;
}
