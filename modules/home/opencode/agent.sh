#!/usr/bin/env bash
# agent — drive the OpenCode VM from the host.
#   agent up | down | status | web | ssh [cmd] | send | fetch | snapshot [name] | restore <name> | wipe
set -euo pipefail

VM_IP=10.77.0.2
KEY="$HOME/.ssh/agent-vm"
SECRETS=/var/lib/agent-vm/secrets/opencode.env
IMG_DIR=/var/lib/microvms/agent
SNAP_DIR=/home/adam/driveBackup/agent-vm-snapshots   # big disk; change if you like
SSH_OPTS=(-i "$KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o ForwardAgent=no -o ForwardX11=no)
vm() { ssh "${SSH_OPTS[@]}" "agent@$VM_IP" "$@"; }

need_repo() { git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "run this inside a git repo" >&2; exit 1; }; }
repo_name() { basename "$(git rev-parse --show-toplevel)"; }
url() { local pw; pw=$(sed -n 's/^OPENCODE_SERVER_PASSWORD=//p' "$SECRETS"); echo "http://opencode:${pw}@${VM_IP}:4096"; }

case "${1:-help}" in
  up)
    # The 22 GB model and Ollama's copy would not both fit in 12 GB of VRAM.
    systemctl stop ollama 2>/dev/null || true
    systemctl start llama-server microvm@agent
    echo -n "waiting for llama-server (first start downloads/loads the model, be patient) "
    until curl -fs http://127.0.0.1:8081/health >/dev/null 2>&1; do
      if ! systemctl is-active --quiet llama-server; then
        echo; echo "llama-server is not running:" >&2
        journalctl -u llama-server -n 30 --no-pager >&2
        exit 1
      fi
      echo -n .; sleep 3
    done
    echo -n "waiting for VM "
    until vm true 2>/dev/null; do echo -n .; sleep 2; done; echo " ok"
    echo "OpenCode: $(url | sed 's/:[^:@]*@/:***@/')   →   run: agent web"
    ;;
  down)
    systemctl stop microvm@agent llama-server
    ;;
  status)
    systemctl --no-pager status microvm@agent llama-server | grep -E "●|Active:" || true
    nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader 2>/dev/null || true
    ;;
  web)
    # Chromium-family app window: looks like a native GUI app, no tabs or URL bar.
    if command -v vivaldi >/dev/null; then exec vivaldi --app="$(url)"; else exec xdg-open "$(url)"; fi
    ;;
  ssh)
    shift; ssh "${SSH_OPTS[@]}" -t "agent@$VM_IP" "$@"
    ;;
  send)
    # Host → VM. The VM never gets a way to reach back; the host always initiates.
    need_repo; n=$(repo_name)
    vm "mkdir -p workspace/$n && cd workspace/$n && { [ -d .git ] || git init -q -b main; } && git config receive.denyCurrentBranch updateInstead"
    GIT_SSH_COMMAND="ssh ${SSH_OPTS[*]}" git push -f "agent@$VM_IP:/var/lib/agent/workspace/$n" HEAD:refs/heads/host
    vm "cd workspace/$n && { git rev-parse --verify -q agent/work >/dev/null || git checkout -q -b agent/work host; }"
    echo "sent '$n' → agent/work (based on your HEAD). Open workspace/$n in the web UI."
    ;;
  fetch)
    # VM → host, pull-only, no hooks. Review before you merge or run anything.
    need_repo; n=$(repo_name)
    GIT_SSH_COMMAND="ssh ${SSH_OPTS[*]}" git -c core.hooksPath=/dev/null fetch \
      "agent@$VM_IP:/var/lib/agent/workspace/$n" "+agent/work:refs/remotes/agent/work"
    echo
    git --no-pager diff --stat HEAD...refs/remotes/agent/work || true
    echo
    echo "Review:  git diff HEAD...agent/work     (look at .envrc, flake.nix, Makefile, package.json scripts, .githooks first)"
    echo "Accept:  git merge --no-commit --no-ff agent/work   or   git cherry-pick <sha>"
    ;;
  snapshot)
    name="${2:-$(date +%Y%m%d-%H%M%S)}"
    systemctl is-active --quiet microvm@agent && { echo "stop the VM first: agent down" >&2; exit 1; }
    mkdir -p "$SNAP_DIR"
    sudo cp --sparse=always "$IMG_DIR/state.img" "$SNAP_DIR/$name.img"
    echo "saved $SNAP_DIR/$name.img"
    ;;
  restore)
    [ -f "$SNAP_DIR/$2.img" ] || { echo "no such snapshot" >&2; ls "$SNAP_DIR"; exit 1; }
    systemctl is-active --quiet microvm@agent && { echo "stop the VM first: agent down" >&2; exit 1; }
    sudo cp --sparse=always "$SNAP_DIR/$2.img" "$IMG_DIR/state.img"
    sudo chown microvm: "$IMG_DIR/state.img" 2>/dev/null || true
    echo "restored $2"
    ;;
  wipe)
    systemctl is-active --quiet microvm@agent && { echo "stop the VM first: agent down" >&2; exit 1; }
    read -rp "Delete the agent's home, sessions and workspace? [y/N] " a; [ "$a" = y ] || exit 1
    sudo rm -f "$IMG_DIR/state.img" "$IMG_DIR/rw-store.img"
    echo "wiped; next 'agent up' recreates empty volumes"
    ;;
  *)
    sed -n '2,3p' "$0" ;;
esac
