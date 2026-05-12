{ pkgs-unstable, ... }: {
  programs.vscode = {
    enable = true;
    package = pkgs-unstable.vscodium-fhs;
    mutableExtensionsDir = true;

    userSettings = {
      "workbench.colorTheme" = "Catppuccin Mocha";
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
}