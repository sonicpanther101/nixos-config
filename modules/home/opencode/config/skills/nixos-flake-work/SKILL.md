---
name: nixos-flake-work
description: Use when editing Nix, NixOS, Home Manager or flake files, or when a build/eval error mentions nix. Explains how to evaluate safely inside this VM.
---

# Working on Nix code in this VM

- The VM cannot switch a real system. Validate with `nix flake check --no-build`, `nix eval`,
  `nix build .#<attr> --dry-run`, and `nixfmt`/`nil` if available (`nix shell nixpkgs#nixfmt-rfc-style nixpkgs#nil`).
- Files must be `git add`ed before flakes can see them.
- Prefer small, evaluable edits; run an eval after each one and read the actual error before changing anything.
- Never invent option names: check with `nix eval` on the option path or search the source under `nixpkgs`.
