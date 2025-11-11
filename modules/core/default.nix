{ inputs, nixpkgs, self, username, host, ...}:{
  imports = 
       [ (import ./bootloader.nix) ];
}