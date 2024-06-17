{
  config,
  lib,
  pkgs,
  modulesPath,
  options,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  powerManagement.cpuFreqGovernor = "performance";

  #------------------------------------------------------------
  # [4070]

  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "555.52.04";
    sha256_64bit = "sha256-nVOubb7zKulXhux9AruUTVBQwccFFuYGWrU1ZiakRAI=";
    sha256_aarch64 = "sha256-Kt60kTTO3mli66De2d1CAoE3wr0yUbBe7eqCIrYHcWk=";
    openSha256 = "sha256-wDimW8/rJlmwr1zQz8+b1uvxxxbOf3Bpk060lfLKuy0=";
    settingsSha256 = "sha256-PMh5efbSEq7iqEMBr2+VGQYkBG73TGUh6FuDHZhmwHk=";
    persistencedSha256 = "sha256-KAYIvPjUVilQQcD04h163MHmKcQrn2a8oaXujL2Bxro=";
  };
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };

  #------------------------------------------------------------
  # [B550]

  systemd.services.bugfixSuspend-GPP0 = {
    enable = lib.mkDefault true;
    description = "Fix crash on wakeup from suspend/hibernate (b550 bugfix)";
    unitConfig = {
      Type = "oneshot";
    };
    serviceConfig = {
      User = "root"; # root may not be necessary
      # check for gppN, disable if enabled
      # lifted from  https://www.reddit.com/r/gigabyte/comments/p5ewjn/comment/ksbm0mb/ /u/Demotay
      ExecStart = "-${pkgs.bash}/bin/bash -c 'if grep 'GPP0' /proc/acpi/wakeup | grep -q 'enabled'; then echo 'GPP0' > /proc/acpi/wakeup; fi'";
      RemainAfterExit = "yes"; # required to not toggle when `nixos-rebuild switch` is ran
    };
    wantedBy = ["multi-user.target"];
  };

  systemd.services.bugfixSuspend-GPP8 = {
    enable = lib.mkDefault true;
    description = "Fix crash on wakeup from suspend/hibernate (b550 bugfix)";
    unitConfig = {
      Type = "oneshot";
    };
    serviceConfig = {
      User = "root";
      ExecStart = "-${pkgs.bash}/bin/bash -c 'if grep 'GPP8' /proc/acpi/wakeup | grep -q 'enabled'; then echo 'GPP8' > /proc/acpi/wakeup; fi''";
      RemainAfterExit = "yes";
    };
    wantedBy = ["multi-user.target"];
  };

  environment.systemPackages = [
    pkgs.openrgb-with-all-plugins
  ];
}
