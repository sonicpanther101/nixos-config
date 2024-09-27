{ config, pkgs, username, host, ... }:
{
  config = {
    # Add user to libvirtd group
    users.users.${username}.extraGroups = [ "libvirtd" ];

    # Install necessary packages
    environment.systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      spice spice-gtk
      spice-protocol
      win-virtio
      win-spice
      adwaita-icon-theme
    ];

    # Manage the virtualisation services
    services.spice-vdagentd.enable = true;

    virtualisation =
      if (host == "desktop") then {
        podman = {
          enable = true;
          dockerCompat = true;
          #defaultNetwork.settings.dns_enabled = true;
        };
    
        oci-containers = {
          backend = "podman";
    
          containers = {
            open-webui = import ./containers/open-webui.nix;
          };
        };
      } else {
        # libvirtd = {
        #   enable = true;
        #   qemu = {
        #     swtpm.enable = true;
        #     ovmf.enable = true;
        #     ovmf.packages = [ pkgs.OVMFFull.fd ];
        #   };
        # };
        # spiceUSBRedirection.enable = true;
      };
  };
}