{ pkgs-unstable, ... } : {
  imports = [
    ./extensions.nix
    ./keybinds.nix
  ];
  
  programs.vscode = {
    enable = true;
    package = pkgs-unstable.vscodium-fhs;
    mutableExtensionsDir = true;

    profiles.default.userSettings = {
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
      "nix.serverPath" = "nixd";
      "wakatime.apiKey" = "REDACTED";
      "extensions.experimental.affinity" = {
        "asvetliakov.vscode-neovim" = 1;
      };
      "clangd.path" = "/home/adam/.config/VSCodium/User/globalStorage/llvm-vs-code-extensions.vscode-clangd/install/21.1.0/clangd_21.1.0/bin/clangd";
    };
  };
}