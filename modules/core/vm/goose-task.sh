#!/usr/bin/env bash
# Run goose autonomously against a sandbox copy of the config (at ~/nixos-config,
# where the rest of the setup expects it), then hand back a diff + report
# through the shared dir. Started by goose-task.service on boot
# (when the host passed a task), or run by hand inside the VM.
set -uo pipefail
export PATH=/run/wrappers/bin:/run/current-system/sw/bin:$PATH

share=/tmp/shared            # host: ~/.local/state/nixos-vm/share
sandbox="$HOME/nixos-config"
out="$share/out"
mkdir -p "$out"
exec > >(tee -a "$out/goose.log") 2>&1

[ -f "$share/task.md" ] || { echo "goose-task: no $share/task.md"; exit 1; }
[ -d "$share/config" ]  || { echo "goose-task: no $share/config"; exit 1; }

# Settings from the host (GOOSE_MODEL, MAX_TURNS, TASK_TIMEOUT, API keys...)
if [ -f "$share/task.env" ]; then set -a; . "$share/task.env"; set +a; fi

echo "== goose-task: preparing sandbox at $sandbox"
rm -rf "$sandbox" "$HOME/REPORT.md"
mkdir -p "$sandbox"
cp -r --no-preserve=mode,ownership "$share/config/." "$sandbox/"
cd "$sandbox"
git init -q -b main
git add -A
git -c user.name=sandbox -c user.email=sandbox@localhost commit -qm baseline

{ cat "$TASK_INSTRUCTIONS"; echo; cat "$share/task.md"; } > "$HOME/INSTRUCTIONS.md"

echo "== goose-task: model=${GOOSE_PROVIDER:-?}/${GOOSE_MODEL:-?} max-turns=${MAX_TURNS:-150} timeout=${TASK_TIMEOUT:-3h}"
timeout "${TASK_TIMEOUT:-3h}" \
    goose run --with-builtin developer --max-turns "${MAX_TURNS:-150}" \
    -i "$HOME/INSTRUCTIONS.md"
echo "== goose-task: goose exited with $?"

# Hand results back (only into the shared out/ dir).
cd "$sandbox"
git add -A
git diff --cached --binary HEAD > "$out/changes.diff"
git diff --cached --stat HEAD    > "$out/changes.stat"

# Human-readable change list: per file, separate Removed / Added blocks with no
# +/- markers (the nixos-config-change-report format). Rendered by us from the
# real files, not written by the agent, so it can't drift from what changed.
if ! vm-changes > "$out/changes.md"; then
    echo "(could not render the change list — apply changes.diff instead)" > "$out/changes.md"
fi

# report.md = the agent's report + the rendered changes.
{
    if [ -f "$HOME/REPORT.md" ]; then
        cat "$HOME/REPORT.md"
    else
        echo "STATUS: FAILED (agent never wrote ~/REPORT.md — see goose.log)"
    fi
    printf '\n## Changes to make to the real config\n\n'
    cat "$out/changes.md"
} > "$out/report.md"
echo "== goose-task: results written to $out"

# Power off when run by systemd, unless the host asked to keep the VM open.
if [ -n "${INVOCATION_ID:-}" ] && [ ! -f "$share/keep" ]; then
    sudo systemctl poweroff
fi
