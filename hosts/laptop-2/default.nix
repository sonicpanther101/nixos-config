{ ... } : {
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];
  my.isLaptop    = true;
  my.hasNvidia   = false;
  my.isHighPower = false;
  my.isDualBoot  = true;
  my.hasPinLogin = true;
  my.pinLoginCode = builtins.readFile /home/adam/.passwd;
  my.pinLoginLength = 4;
}
