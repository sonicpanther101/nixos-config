# ─────────────────────────────────────────────────────────────────────────────
# AGENT VM — guest (nixosConfigurations.agent in flake.nix)
#
# Stateless root (tmpfs). One persistent volume at /var/lib/agent holds the
# agent's home (OpenCode sessions, plugin cache), workspace and ssh host key.
# Wipe that image and the VM is factory-fresh.
# ─────────────────────────────────────────────────────────────────────────────
{ config, lib, pkgs, inputs, ... } : let
  state = "/var/lib/agent";
  home  = "${state}/home";
  cfgDir = "${home}/.config/opencode";
  src = ./../../home/opencode/config;   # OpenCode config sources, kept in the repo
  # Copied (not symlinked) so plugin/tool imports resolve against the writable
  # node_modules beside them. Re-copied every boot: the repo always wins over
  # edits made inside the VM. node_modules itself is never touched.
  managed = [ "opencode.json" "tui.json" "opencode-arise.json" "AGENTS.md" "package.json" "skills" "tools" ];
in {
  system.stateVersion = "26.05";
  networking.hostName = "agent";

  # ───────────── microvm ─────────────
  microvm = {
    hypervisor = "qemu";
    vcpu = 6;
    mem = 6144;                          # MiB. RAM is your tight resource; see README.
    interfaces = [{ type = "tap"; id = "vm-agent"; mac = "02:00:00:00:77:02"; }];

    shares = [
      { proto = "virtiofs"; tag = "ro-store"; source = "/nix/store"; mountPoint = "/nix/.ro-store"; }
      # Only the password file. NOT your projects, NOT your home.
      { proto = "virtiofs"; tag = "secrets"; source = "/var/lib/agent-vm/secrets"; mountPoint = "/run/agent-secrets"; }
    ];
    writableStoreOverlay = "/nix/.rw-store";
    volumes = [
      { image = "rw-store.img"; mountPoint = "/nix/.rw-store"; size = 20 * 1024; }   # nix builds / nix shell
      { image = "state.img";    mountPoint = state;            size = 40 * 1024; }   # sparse; MiB
    ];
  };

  # ───────────── networking (static; host is 10.77.0.1) ─────────────
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.enable = true;
  systemd.network.networks."20-eth" = {
    matchConfig.Type = "ether";
    address = [ "10.77.0.2/24" ];
    gateway = [ "10.77.0.1" ];
  };
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];
  networking.firewall.allowedTCPPorts = [ 22 4096 ];

  # ───────────── the agent user: full freedom inside the VM ─────────────
  users.users.agent = {
    isNormalUser = true;
    uid = 1000;
    home = home;
    createHome = false;                  # tmpfiles below: the volume mounts after activation
    extraGroups = [ "wheel" ];
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [ (lib.removeSuffix "\n" (builtins.readFile ./agent-vm.pub)) ];
  };
  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = { PasswordAuthentication = false; PermitRootLogin = "no"; };
    hostKeys = [{ path = "${state}/ssh_host_ed25519_key"; type = "ed25519"; }];   # stable across reboots
  };

  # ───────────── tools ─────────────
  programs.nix-ld.enable = true;          # pip/npm/bun-installed binaries just work
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    build-dir = "/nix/.rw-store/nix-build";
    trusted-users = [ "agent" ];
  };

  environment.systemPackages = with pkgs; [
    opencode
    git openssh curl wget jq ripgrep fd tree file unzip zip
    gnumake gcc pkg-config
    nodejs bun uv
    (python3.withPackages (p: with p; [ numpy scipy sympy matplotlib pandas mpmath pytest ]))
    poppler-utils pandoc                 # PDFs → text for research
    htop tmux
  ];

  # ───────────── local web search (no API key, no third party) ─────────────
  services.searx = {
    enable = true;
    settings = {
      use_default_settings = true;
      server = { bind_address = "127.0.0.1"; port = 8888; secret_key = "vm-local-throwaway"; };
      search.formats = [ "html" "json" ];
    };
  };

  # ───────────── persistent dirs + declarative OpenCode config ─────────────
  systemd.tmpfiles.rules = [
    "d ${state}                       0755 agent agent -"
    "d ${home}                        0700 agent agent -"
    "d ${state}/workspace             0755 agent agent -"
    "d ${home}/.config                0755 agent agent -"
    "d /nix/.rw-store/nix-build       0755 root  root  -"
    "d ${cfgDir}                      0755 agent agent -"
  ] ++ map (n: "C+ ${cfgDir}/${n} - agent agent - ${src}/${n}") managed;

  # ───────────── OpenCode web server ─────────────
  systemd.services.opencode-web = {
    description = "OpenCode web UI";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "systemd-tmpfiles-setup.service" ];
    wants = [ "network-online.target" ];
    unitConfig.RequiresMountsFor = [ state "/run/agent-secrets" ];
    environment = {
      HOME = home;
      SHELL = "/run/current-system/sw/bin/bash";
      PATH = lib.mkForce "/run/wrappers/bin:/run/current-system/sw/bin";
      OPENCODE_DISABLE_AUTOUPDATE = "1";
      OPENCODE_EXPERIMENTAL_LSP_TOOL = "true";
    };
    serviceConfig = {
      User = "agent";
      WorkingDirectory = "${state}/workspace";
      EnvironmentFile = "/run/agent-secrets/opencode.env";      # OPENCODE_SERVER_PASSWORD
      ExecStart = "${pkgs.opencode}/bin/opencode web --hostname 0.0.0.0 --port 4096";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
