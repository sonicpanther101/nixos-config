{ pkgs-stable, lib, ... }: 
let
  openVsxExtension = { publisher, name, version, sha256, fetchName ? "" }:
    pkgs-stable.stdenv.mkDerivation {
      pname = "vscode-extension-${publisher}-${name}";
      inherit version;
      src = pkgs-stable.fetchurl {
        url = "https://open-vsx.org/api/${publisher}/${name}/${version}/file/${publisher}.${name}-${version}.vsix";
        inherit sha256;
      };
      nativeBuildInputs = [ pkgs-stable.unzip ];
      unpackPhase = "unzip $src";
      installPhase = ''
        mkdir -p $out/share/vscode/extensions/${publisher}.${name}
        cp -r extension/. $out/share/vscode/extensions/${publisher}.${name}/
      '';
      # These attrs are read by home-manager's vscode module
      vscodeExtUniqueId = "${publisher}.${name}";
      vscodeExtPublisher = publisher;
      vscodeExtName = name;
    };
in {
  # Path for most of the nixpkgs vscode extensions is fucked, that's why there is so many manually imported
  programs.vscodium.profiles.default.extensions = with pkgs-stable.vscode-extensions; [
    bbenoist.nix
    catppuccin.catppuccin-vsc-icons
  ] ++ [
    # Extensions not in nixpkgs — built from Open VSX
    # https://open-vsx.org/api/{publisher}/{name}/{version}/file/{publisher}.{name}-{version}.vsix
    # code --list-extensions --show-versions
    (openVsxExtension {
      publisher = "cmillsdev"; name = "strudelvs"; version = "2.1.0";
      sha256 = "sha256-OZ4YJ8K75NbMeze0LMC5dChwmxs2Lp9LejW+ypsyDgE=";
    })
    (openVsxExtension {
      publisher = "cab404"; name = "vscode-direnv"; version = "1.0.0";
      sha256 = "sha256-+nLH+T9v6TQCqKZw6HPN/ZevQ65FVm2SAo2V9RecM3Y=";
    })
    (openVsxExtension {
      publisher = "dunggramer"; name = "vs-aligner"; version = "1.2.1";
      sha256 = "sha256-Wt6DnHPOJnlUA2WIbTRwCJFumJvytS86lnNDQ1A7Wmo=";
    })
    (openVsxExtension {
      publisher = "guyutongxue"; name = "cpp-reference"; version = "0.2.3";
      sha256 = "sha256-lzxqN8MWI5hKUhlCInAZw7xOR3w9Q9LbxX/PiIO+vLE=";
    })
    (openVsxExtension {
      publisher = "pinage404"; name = "nix-extension-pack"; version = "3.0.0";
      sha256 = "sha256-R+bc1x86z3ERczK+KBHnBkdy8KHhXER9+7g6VC2jXY0=";
    })
    (openVsxExtension {
      publisher = "qwtel"; name = "sqlite-viewer"; version = "26.2.5";
      sha256 = "sha256-nc4dHKsvKzh4Qz4t/CO3jsSfxFL5Vx7v+MOY0gSq5fU=";
    })
    (openVsxExtension {
      publisher = "sr-team"; name = "vscode-clangd-cmake"; version = "0.2.0";
      sha256 = "sha256-7gMJI0xzic3RKqVqbdC0Ir6sRfnIvDLlfBb9gQEMZ0E=";
    })
    (openVsxExtension {
      publisher = "wmaurer"; name = "change-case"; version = "1.0.0";
      sha256 = "1qwwsh8ndcvijmkysr212b0w8p0vzi21xsv9qd30iwbaxqq4ag90";
    })
    (openVsxExtension {
      publisher = "moshfeu"; name = "compare-folders"; version = "0.30.0";
      sha256 = "sha256-kuLJFMDSMbkd8mtGZQqyi8ARnPVSidbKjz4d4odGVlY=";
    })
    (openVsxExtension {
      publisher = "ms-vscode"; name = "cmake-tools"; version = "1.23.52";
      sha256 = "sha256-LfYoKiiaETtlq4Jqe1bd5WaS5nBoci9K6BugZjgY2Ho=";
    })
    (openVsxExtension {
      publisher = "ms-python"; name = "python"; version = "2026.4.0";
      sha256 = "sha256-Iyrq+wHwaYJP3ZLT5ijBxEK7z6HTzJRf+XB2NAuytKY=";
    })
    # (openVsxExtension {
    #   publisher = "ms-python"; name = "debugpy"; version = "2026.6.0";
    #   fetchName = "ms-python.debugpy-2026.6.0-darwin-arm64.vsix";
    #   sha256 = "sha256-NCW1JRsPBkK1aeZDl+/+cqsUHROKvZZrVnBBuqVgm0s=";
    # })
    (openVsxExtension {
      publisher = "llvm-vs-code-extensions"; name = "vscode-clangd"; version = "0.4.0";
      sha256 = "sha256-r71PACuJZBASsWYFHKoq8vVu1zK32/S8AKVtCJHkGqk=";
    })
    (openVsxExtension {
      publisher = "esbenp"; name = "prettier-vscode"; version = "12.4.0";
      sha256 = "sha256-+3MOpDBtCc3Ao6qp6bquKAWMyXpPv86LBWs3egY5qf4=";
    })
    (openVsxExtension {
      publisher = "asvetliakov"; name = "vscode-neovim"; version = "1.19.0";
      sha256 = "sha256-DWK7daxHjHOKY7HHCeI89eWTYaIPB2LQ/C1VdnyIqu8=";
    })
  ];

  home.activation.catppuccinVsc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ext_src="${pkgs-stable.vscode-extensions.catppuccin.catppuccin-vsc}/share/vscode/extensions/catppuccin.catppuccin-vsc"
    ext_dst="$HOME/.vscode-oss/extensions/catppuccin.catppuccin-vsc"
    rm -rf "$ext_dst"
    cp -r "$ext_src" "$ext_dst"
    chmod -R +w "$ext_dst"
  '';
}