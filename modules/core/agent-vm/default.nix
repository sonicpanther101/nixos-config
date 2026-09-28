# ─────────────────────────────────────────────────────────────────────────────
# AGENT VM — host side (desktop only)
#
#   host ── br-agent 10.77.0.1 ──┬── microvm "agent" 10.77.0.2  (OpenCode runs here)
#                                └── llama-server :8081 on the host (GPU)
#
# The VM may reach: llama-server (8081) and the public internet.
# The VM may NOT reach: your LAN/router, other host ports (sshd, Radicale,
# Sunshine, Open WebUI, Ollama), docker0, or anything RFC1918.
#
# Imported from hosts/desktop/default.nix. Needs `inputs.microvm.nixosModules.host`
# in the desktop's module list (flake.nix) and a `nixosConfigurations.agent`.
# ─────────────────────────────────────────────────────────────────────────────
{ self, pkgs, pkgs-stable, lib, username, ... } : let
  bridge  = "br-agent";
  hostIp  = "10.77.0.1";
  guestIp = "10.77.0.2";
  subnet  = "10.77.0.0/24";
  ext     = "enp6s0";                 # same NIC network.nix already refers to
  llamaPort = 8081;

  # CUDA build of llama.cpp for the 4070 only (sm_89) so the local compile is
  # shorter. First build is slow (unfree CUDA is not on cache.nixos.org);
  # add https://cache.nixos.org alternatives such as cuda-maintainers.cachix.org
  # if you want to avoid compiling it.
  llamaCpp = (pkgs-stable.llama-cpp.override { cudaSupport = true; }).overrideAttrs (o: {
    cmakeFlags = (o.cmakeFlags or []) ++ [ "-DCMAKE_CUDA_ARCHITECTURES=89" ];
  });

  # ── Model. Check the repo's file list for the exact quant tag. ──
  model = "unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q4_K_M";
in {

  # ── VM definition (guest lives in flake.nix as nixosConfigurations.agent) ──
  microvm.vms.agent.flake = self;
  # No autostart: the VM and the 22 GB model are started on demand by `agent up`.

  # ── Bridge for the VM, managed by networkd; NetworkManager stays out of it ──
  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;   # NM already handles "online"
  systemd.network.netdevs."30-${bridge}".netdevConfig = { Kind = "bridge"; Name = bridge; };
  systemd.network.networks."30-${bridge}" = {
    matchConfig.Name = bridge;
    address = [ "${hostIp}/24" ];
    networkConfig.ConfigureWithoutCarrier = true;
    linkConfig.RequiredForOnline = "no";
  };
  systemd.network.networks."31-vm-agent" = {
    matchConfig.Name = "vm-agent";
    networkConfig.Bridge = bridge;
    linkConfig.RequiredForOnline = "no";
  };
  networking.networkmanager.unmanaged = [ "interface-name:${bridge}" "interface-name:vm-agent" ];
  networking.dhcpcd.denyInterfaces = [ bridge "vm-agent" ];

  # ── NAT + firewall: internet yes, LAN and host services no ──
  networking.nat = {
    enable = true;
    internalInterfaces = [ bridge ];
    externalInterface = ext;
  };
  networking.firewall.extraCommands = ''
    # INPUT (VM → host): only llama-server. Inserted in reverse order so the
    # final order is: established → llama port → drop everything else.
    iptables -I nixos-fw 1 -i ${bridge} -j DROP
    iptables -I nixos-fw 1 -i ${bridge} -p tcp --dport ${toString llamaPort} -j ACCEPT
    iptables -I nixos-fw 1 -i ${bridge} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # FORWARD (VM → world). Docker sets FORWARD policy DROP, so accept explicitly,
    # but never toward private/LAN/link-local/CGNAT ranges.
    iptables -N agent-fwd 2>/dev/null || true
    iptables -F agent-fwd
    for net in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 169.254.0.0/16 100.64.0.0/10; do
      iptables -A agent-fwd -d $net -j REJECT
    done
    iptables -A agent-fwd -j ACCEPT
    iptables -C FORWARD -o ${bridge} -j DROP 2>/dev/null || iptables -I FORWARD 1 -o ${bridge} -j DROP
    iptables -C FORWARD -o ${bridge} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null \
      || iptables -I FORWARD 1 -o ${bridge} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -C FORWARD -i ${bridge} -j agent-fwd 2>/dev/null || iptables -I FORWARD 1 -i ${bridge} -j agent-fwd
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D FORWARD -i ${bridge} -j agent-fwd 2>/dev/null || true
    iptables -D FORWARD -o ${bridge} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -o ${bridge} -j DROP 2>/dev/null || true
    iptables -F agent-fwd 2>/dev/null || true
    iptables -X agent-fwd 2>/dev/null || true
  '';

  # ── OpenCode's web password: generated once, shared read-only with the VM ──
  systemd.services.agent-vm-secrets = {
    wantedBy = [ "multi-user.target" ];
    before = [ "microvm@agent.service" ];
    serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
    script = ''
      d=/var/lib/agent-vm/secrets
      mkdir -p "$d"
      if [ ! -s "$d/opencode.env" ]; then
        printf 'OPENCODE_SERVER_PASSWORD=%s\n' "$(${pkgs.openssl}/bin/openssl rand -hex 16)" > "$d/opencode.env"
      fi
      chmod 755 "$d"; chmod 644 "$d/opencode.env"
    '';
  };

  # ── llama.cpp server (started on demand by `agent up`) ──
  systemd.services.llama-server = {
    description = "llama.cpp server for the agent VM";
    after = [ "network.target" ];
    startLimitIntervalSec = 120;
    startLimitBurst = 3;
    # deliberately no wantedBy: it holds ~11 GB VRAM and ~12 GB RAM while running
    environment = {
      LLAMA_CACHE = "/var/lib/llama-cpp";
      HOME = "/var/lib/llama-cpp";
    };
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "llama-cpp";
      SupplementaryGroups = [ "video" "render" ];
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStartSec = "30min";   # first start downloads ~21 GB
      ExecStart = lib.concatStringsSep " " [
        "${llamaCpp}/bin/llama-server"
        "-hf ${model}"
        "--alias qwen3.6-35b-a3b"
        "--host 0.0.0.0 --port ${toString llamaPort}"   # reachable only via the firewall rules above
        "-c 262144"                       # native context. See README for why not 1M.
        "-np 1"                           # one slot = full context; raise to 2 for parallel shadows
        "-ngl 99"
        "--n-cpu-moe 36"     # was 32: fewer expert layers on GPU, frees ~2 GB
        "-fa on"
        "--cache-type-k q8_0 --cache-type-v q8_0"
        "-b 2048 -ub 512"    # was -ub 1024: roughly halves the compute buffer
        "--jinja"
        "--reasoning-format deepseek"     # reasoning arrives as reasoning_content, streamed live
        "--no-mmproj-offload"             # keep the vision projector out of the 12 GB
        "--temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.0"
      ];
    };
  };

  # ── Let you start/stop these without sudo ──
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      var units = ["microvm@agent.service", "llama-server.service", "ollama.service"];
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          units.indexOf(action.lookup("unit")) >= 0 &&
          subject.user == "${username}") {
        return polkit.Result.YES;
      }
    });
  '';

  # Ollama keeps a model resident for an hour; that fights llama-server for VRAM.
  services.ollama.environmentVariables.OLLAMA_KEEP_ALIVE = lib.mkForce "5m";
}
