# Host-side glue for the OpenCode VM: the `agent` command and a launcher entry.
# The OpenCode config itself lives in ./config and is deployed *into the VM*
# by modules/core/agent-vm/guest.nix — the host no longer has an unsandboxed
# opencode.json (see the removal in programs.nix).
{ lib, pkgs-stable, isHighPower, ... } : {
  config = lib.mkIf isHighPower {
  home.packages = [
    (pkgs-stable.writeShellScriptBin "agent" (builtins.readFile ./agent.sh))
  ];

  xdg.desktopEntries.opencode-vm = {
    name = "OpenCode (VM)";
    comment = "Sandboxed coding agent";
    exec = "agent web";
    icon = "utilities-terminal";
    categories = [ "Development" ];
  };
  };
}
