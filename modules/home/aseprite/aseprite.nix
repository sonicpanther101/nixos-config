{ pkgs-stable, ... }: 
{
  home.packages = (with pkgs-stable; [ aseprite ]);
}
