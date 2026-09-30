# ─────────────────────────────────────────────────────────────────────────────
# VM — a throwaway copy of this exact host, run under QEMU (high-power hosts only)
#
# Uses NixOS's built-in `virtualisation.vmVariant`: the VM is the *same*
# configuration as the host it is built from (same modules, same home-manager,
# same Hyprland rice), with only the overrides below applied on top. Nothing in
# here affects the real system — vmVariant is only evaluated by `build-vm`.
#
# Usage (on a high-power host):
#     my-vm                        # build (if needed) and start the VM
#     my-vm -r                     # wipe the VM's disk first (fresh state)
#     my-vm -b                     # only build, don't start
#     my-vm -t "fix X" [-H] [-k]   # let goose CLI work on a goal inside the VM
#                                  # (see the AI SANDBOX section below / README)
#
# The whole thing is gated on `my.isHighPower`: on any other host the variant
# is empty (so a plain `build-vm` gives a stock VM) and `my-vm` isn't installed.
# ─────────────────────────────────────────────────────────────────────────────
{ config, lib, host, username, pkgs-stable, pkgs-unstable, ... }: let

  # Guest-side helpers for the AI sandbox (only ever installed in the VM).
  vmRebuild = pkgs-stable.writeShellScriptBin "vm-rebuild"
    (builtins.readFile ./vm-rebuild.sh);

  gooseTask = pkgs-stable.writeShellScriptBin "goose-task"
    ("export TASK_INSTRUCTIONS=${./goose-instructions.md}\n"
      + builtins.readFile ./goose-task.sh);

in {

  virtualisation.vmVariant = lib.mkIf config.my.isHighPower {

    # ─── Resources ───────────────────────────────────────────────────────────
    virtualisation = {
      memorySize = 12 * 1024; # MiB — evaluating + building this flake needs room
      cores = 6;
      diskSize = 48 * 1024;   # MiB — sparse; holds state AND anything built inside the VM

      # Store new paths on the disk image instead of a RAM-backed tmpfs, so
      # rebuilding inside the VM (goose sandbox) can't run it out of memory.
      writableStoreUseTmpfs = false;

      # Hyprland needs a real (virgl) GPU, plain VGA won't do. Both are
      # overridable from the host (my-vm -H uses them for headless mode).
      graphics = true;
      qemu.options = [
        "\${MY_VM_GPU:--device virtio-vga-gl}"
        "-display \${MY_VM_DISPLAY:-gtk,gl=on}"
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
    # Disposable machine: no sudo prompts, so an agent can `sudo` without a human.
    security.sudo.wheelNeedsPassword = lib.mkVMOverride false;

    # ─── AI SANDBOX ──────────────────────────────────────────────────────────
    # `my-vm -t "<goal>"` shares a *snapshot* of the config (no .git) plus the
    # task into the VM at /tmp/shared (qemu-vm's built-in `shared` dir, pointed
    # at $SHARED_DIR by my-vm). On boot, goose-task.service copies it to
    # ~/sandbox-config, lets goose CLI iterate with `vm-rebuild` until the goal
    # is met, and writes changes.diff + report.md back to /tmp/shared/out.
    # The real repo and the host system are never written to.
    environment.systemPackages = [
      pkgs-unstable.goose-cli
      pkgs-stable.git
      vmRebuild
      gooseTask
    ];

    environment.variables = {
      GOOSE_PROVIDER = "ollama";
      GOOSE_MODE = "auto"; # never stop to ask permission — it's a sandbox
      GOOSE_DISABLE_KEYRING = "1"; # no keyring daemon in the VM
      # 10.0.2.2 is the host as seen from QEMU's user-mode network. It reaches
      # the host's loopback, where ollama listens.
      OLLAMA_HOST = "http://10.0.2.2:11434";
      GOOSE_MODEL = "qwen3.6:35b-a3b-mtp-q4_K_M"; # override with `my-vm -m <model>`
    };

    systemd.services.goose-task = {
      description = "Autonomous goose run against a sandbox copy of the config";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      # Only when the host actually passed a task.
      unitConfig = {
        ConditionPathExists = "/tmp/shared/task.md";
        RequiresMountsFor = "/tmp/shared";
      };
      # vm-rebuild re-activates the system while this runs — don't let that
      # restart (i.e. kill) the agent that's doing it.
      restartIfChanged = false;
      stopIfChanged = false;
      environment = {
        HOME = "/home/${username}";
        GOOSE_PROVIDER = "ollama";
        GOOSE_MODE = "auto";
        GOOSE_DISABLE_KEYRING = "1";
        OLLAMA_HOST = "http://10.0.2.2:11434";
        GOOSE_MODEL = "qwen3.6:35b-a3b-mtp-q4_K_M";
      };
      serviceConfig = {
        User = username;
        ExecStart = "${gooseTask}/bin/goose-task";
      };
    };
  };
}
