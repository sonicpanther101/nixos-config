{ ... } : {
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];
  my.isLaptop    = true;
  my.hasNvidia   = false;
  my.isHighPower = false;
  my.isDualBoot  = false;
}