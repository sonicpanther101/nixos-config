# ── nix-ld.nix ───────────────────────────────────────────────────────────────
# TIP: uv/pip/pipx install prebuilt Python wheels (tokenizers, numpy, torch,
# etc) that expect FHS paths like /usr/lib for their compiled extensions.
# NixOS doesn't have those paths, so these binaries fail with errors like
# "ImportError: libstdc++.so.6: cannot open shared object file".
#
# nix-ld patches the ELF interpreter for such unpatched binaries so they can
# find Nix-provided libraries instead. This is the general fix for that
# whole class of error from tools like `uvx openhands`, `pip install`, etc.
# ─────────────────────────────────────────────────────────────────────────────
{ pkgs-stable, ... }: {
  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs-stable; [
    stdenv.cc.cc.lib   # libstdc++.so.6 — fixes the tokenizers error
    zlib
    openssl
    curl
    libxml2
    glib
  ];
}
