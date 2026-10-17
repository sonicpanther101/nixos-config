{ ... } : {
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];
  my.isLaptop    = false;
  my.hasNvidia   = true;
  my.isHighPower = true;
  my.isDualBoot  = false;
  my.wakeOnLanInterface = "enp6s0";
}
