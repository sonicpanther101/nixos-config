# ─────────────────────────────────────────────────────────────────────────────
# VM — a throwaway copy of this exact host, run under QEMU (high-power hosts only)
#
# Uses NixOS's built-in `virtualisation.vmVariant`: the VM is the *same*
# configuration as the host it is built from (same modules, same home-manager,
# same Hyprland rice), with only the overrides below applied on top. Nothing in
# here affects the real system — vmVariant is only evaluated by `build-vm`.
#
# Usage (on a high-power host):
#     my-vm            # build (if needed) and start the VM
#     my-vm -r         # wipe the VM's disk first (fresh state)
#     my-vm -b         # only build, don't start
#
# or by hand:
#     nixos-rebuild build-vm --flake ~/nixos-config#desktop && ./result/bin/run-desktop-vm-vm
#
# The whole thing is gated on `my.isHighPower`: on any other host the variant
# is empty (so a plain `build-vm` gives a stock VM) and `my-vm` isn't installed.
# ─────────────────────────────────────────────────────────────────────────────
{ config, lib, host, username, ... }: {

  virtualisation.vmVariant = lib.mkIf config.my.isHighPower {

    # ─── Resources ───────────────────────────────────────────────────────────
    virtualisation = {
      memorySize = 8 * 1024; # MiB
      cores = 4;
      diskSize = 32 * 1024;  # MiB — /nix/store is shared from the host, this is just state

      # Hyprland needs a real (virgl) GPU, plain VGA won't do.
      graphics = true;
      qemu.options = [
        "-device virtio-vga-gl"
        "-display gtk,gl=on"
      ];
    };

    # ─── Things that only make sense on the physical machine ─────────────────
    # No GPU is passed through, so pretend there's no Nvidia card. This also
    # flows into home-manager (btop-cuda etc.) via my.hasNvidia.
    my.hasNvidia = lib.mkVMOverride false;

    networking.hostName = lib.mkVMOverride "${host}-vm";
    networking.interfaces = lib.mkVMOverride { }; # enp6s0 / wake-on-lan doesn't exist here

    # The VM direct-boots its kernel and never shows GRUB, so drop the GRUB theme
    # (its gfxmodeBios clashes with qemu-vm's own) and skip fetching its splash image.
    boot.loader.grub2-theme.enable = lib.mkVMOverride false;
    boot.loader.grub.gfxmodeBios = lib.mkVMOverride "1024x768";

    # by-uuid resume device + swapfile offset + nvidia params from the host don't exist here.
    boot.resumeDevice = lib.mkVMOverride "";
    boot.kernelParams = lib.mkVMOverride [ ];

    # GPU / hardware-bound or heavy services that would just fail or eat RAM.
    # Delete a line to get that service back in the VM.
    services.ollama.enable = lib.mkVMOverride false;     # would try to pull ~30GB of models
    services.open-webui.enable = lib.mkVMOverride false;
    services.sunshine.enable = lib.mkVMOverride false;
    virtualisation.libvirtd.enable = lib.mkVMOverride false; # no nested VMs

    # ─── Login ───────────────────────────────────────────────────────────────
    # The real user's password is set imperatively, so in the VM it'd have none
    # (autologin still works, but sudo would be unusable).
    users.users.${username}.initialPassword = lib.mkVMOverride "vm";
  };
}
