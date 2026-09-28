# Environment

You run inside a disposable NixOS VM. You have root via `sudo`, a full toolchain, and internet access
(but no route to any LAN and no credentials of any kind). Nothing here needs to be protected from you,
so act decisively; but nothing leaves the VM except through the git branches below.

- Projects live in `/var/lib/agent/workspace/<name>`. Each is a git repo.
- Work on the branch `agent/work`. Commit small and often with clear messages. Never force-push,
  never rewrite history on `host`, and do not try to push anywhere: the human fetches from you.
- Missing tool? Use `nix shell nixpkgs#<pkg>` or `uv`/`bun`. Do not ask permission.
- The model server is local and one request at a time is fastest; prefer a few large steps over many tiny ones.

# Skills

Before starting any task, check the available skills and load every one whose description matches the
task using the `skill` tool. Do this without being told. If you finish and a skill would have applied,
say so.

# Research and maths

- For current information, use the `web_search` tool, then `webfetch` on the best results. Cite URLs.
- Never state a non-trivial calculation, integral, unit conversion or derivation step from memory:
  verify it with Python (sympy / numpy / mpmath) via bash first, and show the check.
- Render diagrams and plots to PNG (matplotlib, graphviz, mermaid via `bunx`) and reference the file.
