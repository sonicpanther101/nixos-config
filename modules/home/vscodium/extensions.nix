{ pkgs-stable, ... }: 
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
  programs.vscode.profiles.default.extensions = with pkgs-stable.vscode-extensions; [
    asvetliakov.vscode-neovim
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
      publisher = "catppuccin"; name = "catppuccin-vsc"; version = "3.18.1";
      sha256 = "16hxf4ka2cj46vlcz8xl0vpf21d1jxkrydmaaq1jhi8v12fpk61a";
    })
    (openVsxExtension {
      publisher = "WakaTime"; name = "vscode-wakatime"; version = "25.3.2";
      sha256 = "033456jmrkdlzvixk7qwhk9a5h3lacbpwrg3f3iqln4sw7psli15";
    })
    (openVsxExtension {
      publisher = "wmaurer"; name = "change-case"; version = "1.0.0";
      sha256 = "1qwwsh8ndcvijmkysr212b0w8p0vzi21xsv9qd30iwbaxqq4ag90";
    })
    (openVsxExtension {
      publisher = "moshfeu"; name = "compare-folders"; version = "0.25.3";
      sha256 = "1l3fvhw8b4ag23fm6942phqxvajm8wfk6dzw1b1f546h7i253icn";
    })
    (openVsxExtension {
      publisher = "ms-vscode"; name = "cmake-tools"; version = "1.21.36";
      sha256 = "060rmdg73axhifljp8pp7n8a9gcyv314gr4yk2b8xkq8xffiia12";
    })
    (openVsxExtension {
      publisher = "ms-python"; name = "python"; version = "2025.16.0";
      sha256 = "1gyvp6d783a9qd94d6fikch2x9w76y6gwbqmin5b1c0yh4470qsz";
    })
    # (openVsxExtension {
    #   publisher = "ms-python"; name = "debugpy"; version = "2026.6.0";
    #   fetchName = "ms-python.debugpy-2026.6.0-darwin-arm64.vsix";
    #   sha256 = "sha256-NCW1JRsPBkK1aeZDl+/+cqsUHROKvZZrVnBBuqVgm0s=";
    # })
    (openVsxExtension {
      publisher = "llvm-vs-code-extensions"; name = "vscode-clangd"; version = "0.2.0";
      sha256 = "05zhkavj77lhskwgj4yjh83253gjrpsm97l8nyhq83xlihy3ppd7";
    })
    (openVsxExtension {
      publisher = "esbenp"; name = "prettier-vscode"; version = "11.0.0";
      sha256 = "1iyahpy3b53cajwzd7drhggzg8mc6ldx8xi414vpvyjps6xz8nfr";
    })
  ];
}