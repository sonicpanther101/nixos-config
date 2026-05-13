{ pkgs-stable, pkgs-unstable, ... }: 
let
  openVsxExtension = { publisher, name, version, sha256 }:
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
  programs.vscode = {
    enable = true;
    package = pkgs-unstable.vscodium-fhs;
    mutableExtensionsDir = true;
    

    profiles.default = {
      extensions = with pkgs-stable.vscode-extensions; [
        asvetliakov.vscode-neovim
        bbenoist.nix
        catppuccin.catppuccin-vsc
        catppuccin.catppuccin-vsc-icons
        esbenp.prettier-vscode
        jnoortheen.nix-ide
        llvm-vs-code-extensions.vscode-clangd
        ms-python.python
        ms-python.debugpy
        ms-vscode.cmake-tools
        wakatime.vscode-wakatime
        moshfeu.compare-folders
        wmaurer.change-case
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
      ];

      userSettings = {
        "workbench.colorTheme" = "Catppuccin Mocha";
        "workbench.iconTheme" = "catppuccin-mocha";
        "catppuccin.accentColor" = "blue";
        "files.autoSave" = "afterDelay";
        "git.enableSmartCommit" = true;
        "git.confirmSync" = false;
        "git.autofetch" = true;
        "git.postCommitCommand" = "sync";
        "workbench.sideBar.location" = "right";
        "security.workspace.trust.enabled" = false;
        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;
        "terminal.integrated.tabs.enabled" = false;
        "editor.lineNumbers" = "relative";
        "editor.fontLigatures" = true;
        "terminal.integrated.initialHint" = false;
        "terminal.integrated.enableMultiLinePasteWarning" = "never";
        "python.analysis.typeCheckingMode" = "basic";
        "python.analysis.useLibraryCodeForTypes" = true;
        "python.analysis.autoImportCompletions" = true;
        "python.analysis.indexing" = true;
        "python.defaultInterpreterPath" = "";
        "wakatime.apiKey" = "REDACTED";
        "extensions.experimental.affinity" = {
          "asvetliakov.vscode-neovim" = 1;
        };
        "clangd.path" = "/home/adam/.config/VSCodium/User/globalStorage/llvm-vs-code-extensions.vscode-clangd/install/21.1.0/clangd_21.1.0/bin/clangd";
      };

      keybindings = [
        { key = "ctrl+w"; command = "-workbench.action.closeActiveEditor"; }
        { key = "ctrl+w"; command = "workbench.action.closeActiveEditor"; }
        { key = "alt+f4"; command = "-workbench.action.closeWindow"; }
        { key = "ctrl+shift+w"; command = "-workbench.action.closeWindow"; }
        { key = "ctrl+q"; command = "-workbench.action.quit"; }
        { key = "ctrl+q"; command = "editor.action.commentLine";
          when = "editorTextFocus && !editorReadonly"; }
        { key = "ctrl+/"; command = "-editor.action.commentLine";
          when = "editorTextFocus && !editorReadonly"; }
        { key = "ctrl+y"; command = "redo"; }
        { key = "ctrl+shift+z"; command = "-redo"; }
        { key = "ctrl+space"; command = "python.execInTerminal"; }
        { key = "ctrl+space"; command = "-editor.action.triggerSuggest";
          when = "editorHasCompletionItemProvider && textInputFocus && !editorReadonly && !suggestWidgetVisible"; }
        { key = "ctrl+space"; command = "strudel.play";
          when = "resourceLangId == 'strudel'"; }
        { key = "ctrl+enter"; command = "-strudel.play";
          when = "resourceLangId == 'strudel'"; }
        { key = "ctrl+shift+space"; command = "python.setInterpreter"; }
        { key = "ctrl+shift+space"; command = "-editor.action.triggerParameterHints";
          when = "editorHasSignatureHelpProvider && editorTextFocus"; }
        { key = "ctrl+t"; command = "-workbench.action.showAllSymbols"; }
      ];
    };
  };
}