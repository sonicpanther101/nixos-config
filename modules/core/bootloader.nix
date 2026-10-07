{ config, pkgs-stable, pkgs-unstable, lib, host, ... }:{

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      timeout = 5;
      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiSupport = true;
        useOSProber = config.my.isDualBoot;
        memtest86.enable = true;
        timeoutStyle = "menu";
      };
    };

    # Styling bootloader
    loader.grub2-theme = {
      enable = true;
      theme = "stylish";
      footer = true;
      splashImage = pkgs-stable.fetchurl {
        url = "https://raw.githubusercontent.com/sonicpanther101/wallpapers/refs/heads/main/others/nixos-catppuccin.png";
        sha256 = "sha256-BWiy7wLWHHPjvvElEbdJt75ht/lZtJMi/LlnPeaV0XM=";
      };
    };

    # For windows filesystems to work
    supportedFilesystems = [ "ntfs" ];

    # Getting sleep to work
    kernelParams = [ "acpi_enforce_resources=lax" ] ++ lib.optionals config.my.hasNvidia [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" "usbcore.autosuspend=1" "amd_iommu=on" ];

    kernelPackages = lib.mkIf config.my.hasNvidia pkgs-unstable.linuxPackages;

    kernelPatches = lib.optionals (host == "laptop-1") [{
      name = "surface-trimmed-config";
      patch = null;
      structuredExtraConfig = with lib.kernel; {
        # Biggest saving: skips DWARF generation + the pahole/BTF step.
        # Only needed for CO-RE eBPF tools (bpftrace, bcc, ...).
        DEBUG_INFO_BTF = lib.mkForce no;
        DEBUG_INFO_BTF_MODULES = lib.mkForce no;

        # GPUs the Surface doesn't have (Intel i915/xe stays)
        DRM_AMDGPU = lib.mkForce no;
        DRM_RADEON = lib.mkForce no;
        DRM_NOUVEAU = lib.mkForce no;

        # TV tuners / DVB / SDR / FM radio (webcams and IPU3 cameras stay)
        # With the filter off, Kconfig forces all the *_SUPPORT bools below to y,
        # so it has to be on for them to be switchable.
        MEDIA_SUPPORT_FILTER = lib.mkForce yes;
        MEDIA_DIGITAL_TV_SUPPORT = lib.mkForce no;
        MEDIA_ANALOG_TV_SUPPORT = lib.mkForce no;
        MEDIA_RADIO_SUPPORT = lib.mkForce no;
        MEDIA_SDR_SUPPORT = lib.mkForce no;

        # Datacentre / AMD-only stuff
        INFINIBAND = lib.mkForce no;
        KVM_AMD = lib.mkForce no;

        # PCI/server Ethernet vendors (mellanox, qlogic, netronome, sfc, ...).
        # USB ethernet adapters / docks are USB_NET_DRIVERS, so they stay.
        ETHERNET = lib.mkForce no;

        # Accelerators / exotic bus & server hardware
        DRM_ACCEL = lib.mkForce no;   # habanalabs, qaic, amdxdna, ivpu
        VDPA = lib.mkForce no;
        RAPIDIO = lib.mkForce no;
        LIBNVDIMM = lib.mkForce no;
        DPLL = lib.mkForce no;
        PARPORT = lib.mkForce no;
        PCMCIA = lib.mkForce no;
        SCSI_LOWLEVEL = lib.mkForce no; # RAID/HBA cards; USB storage and NVMe unaffected
        HAMRADIO = lib.mkForce no;
        CAN = lib.mkForce no;
        NFC = lib.mkForce no;
      };
    }];

  } // lib.optionalAttrs config.my.isHighPower {

    # XBox controller
    extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];
    extraModprobeConfig = ''
      options bluetooth disable_ertm=Y
    '';

    # OpenRGB
    kernelModules = [ "i2c-dev" ];
  };

  # Sleep config
  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "30m";
    SuspendState = "mem";
  };
}
