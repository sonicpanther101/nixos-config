{ pkgs, inputs, username, host, pkgs-stable, ...}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];
  config = {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = [];
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      extraSpecialArgs = { inherit inputs username host pkgs-stable; };
      users.${username} = {
        imports = 
          if (host == "desktop") then 
            [ ./../home/default.desktop.nix ] 
          else [ ./../home ];
        home.username = "${username}";
        home.homeDirectory = "/home/${username}";
        home.stateVersion = "25.05";
        programs.home-manager.enable = true;
      };
    };

    environment.sessionVariables = {
      FLAKE = "/home/${username}/nixos-config";
      CUDA_PATH = 
        if (host == "desktop") then 
         "${pkgs.cudatoolkit}"
        else "";
      LD_LIBRARY_PATH = 
        if (host == "desktop") then
          "${pkgs.wayland}/lib:${pkgs.wayland.dev}/lib:/run/opengl-driver/lib:${pkgs.stdenv.cc.cc.lib}/lib:/usr/lib/wsl/lib:${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.ncurses5}/lib:$(nix build --print-out-paths --no-link nixpkgs#libGL)/lib:${pkgs.icu74}/lib:${pkgs.python310}/lib"
        else "${pkgs.wayland}/lib:${pkgs.wayland.dev}/lib:${pkgs.libepoxy}/lib:${pkgs.libva1}/lib:${pkgs.libva}/lib";
      EXTRA_LDFLAGS = 
        if (host == "desktop") then 
          "-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
        else "";
      EXTRA_CCFLAGS = 
        if (host == "desktop") then
          "-I/usr/include"
        else "";
    };

    users.users.${username} = {
      isNormalUser = true;
      description = "${username}";
      extraGroups = 
        if (host == "laptop") then 
          [ "networkmanager" "wheel" "surface-control" ]
        else [ "networkmanager" "wheel" ];
      shell = pkgs.zsh;
    };
    nix.settings.allowed-users = [ "${username}" ];
  };
}
