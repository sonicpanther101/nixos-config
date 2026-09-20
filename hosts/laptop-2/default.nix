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
  my.pinLoginCode = "MTU5MA==";
  my.pinLoginLength = 4;
}
