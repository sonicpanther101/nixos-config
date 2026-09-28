{ ... } : {
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
    ./../../modules/core/agent-vm
  ];
  my.isLaptop    = false;
  my.hasNvidia   = true;
  my.isHighPower = true;
  my.isDualBoot  = false;
}
