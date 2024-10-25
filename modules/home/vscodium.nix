{ pkgs, ... }: 
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      # nix language
      bbenoist.nix
      # nix-shell suport 
      arrterian.nix-env-selector
      # python
      ms-python.python
      # C/C++
      ms-vscode.cpptools

      # Color theme
      catppuccin.catppuccin-vsc
      catppuccin.catppuccin-vsc-icons

      # Python
      matangover.mypy
      charliermarsh.ruff
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    
    ];
    userSettings = {
      "update.mode" = "none";
      "extensions.autoUpdate" = "onlyEnabledExtensions"; # This stuff fixes vscode freaking out when theres an update
      "window.titleBarStyle" = "custom"; # needed otherwise vscode crashes, see https://github.com/NixOS/nixpkgs/issues/246509

      "window.menuBarVisibility" = "visible";
      "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'SymbolsNerdFont', 'monospace', monospace";
      "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font', 'SymbolsNerdFont'";
      "editor.fontSize" = 16;
      "workbench.iconTheme" = "catppuccin-mocha";
      "catppuccin.accentColor" = "blue";
      "vsicons.dontShowNewVersionMessage" = true;
      "explorer.confirmDragAndDrop" = false;
      "editor.fontLigatures" = true;
      "editor.minimap.enabled" = true;
      "workbench.startupEditor" = "none";

      "editor.formatOnSave" = true;
      "editor.formatOnType" = true;
      "editor.formatOnPaste" = true;

      "workbench.layoutControl.type" = "menu";
      "workbench.editor.limit.enabled" = true;
      "workbench.editor.limit.value" = 10;
      "workbench.editor.limit.perEditorGroup" = true;
      "workbench.editor.showTabs" = "multiple";
      "files.autoSave" = "afterDelay";
      "explorer.openEditors.visible" = 1;
      "breadcrumbs.enabled" = true;
      "editor.renderControlCharacters" = false;
      "workbench.activityBar.location" = "default";
      "workbench.sideBar.location" = "right";
      "workbench.statusBar.visible" = true;
      "editor.scrollbar.verticalScrollbarSize" = 2;
      "editor.scrollbar.horizontalScrollbarSize" = 2;
      "editor.scrollbar.vertical" = "hidden";
      "editor.scrollbar.horizontal" = "hidden";
      "workbench.layoutControl.enabled" = true;
      "git.autofetch" = true;
      "git.enableSmartCommit" = true;
      "git.postCommitCommand" = "push";
      "security.workspace.trust.enabled" = false;
      "codeium.enableConfig" = {
        "*" = true;
        "markdown" = true;
        "nix" = true;
      };
      "explorer.confirmDelete" = false;
      "workbench.colorTheme" = "Catppuccin Mocha";
      "explorer.confirmPasteNative" = false;
      "git.confirmSync" = false;
      "terminal.integrated.persistentSessionScrollback" = 10000;
      "color-highlight.matchHslWithNoFunction" = true;
      "color-highlight.matchRgbWithNoFunction" = true;
      "diffEditor.ignoreTrimWhitespace" = false;
      "files.exclude" = {
        "**/.vscode" = true;
        "**/node_modules" = true;
      };
      "spotify.forceWebApiImplementation" = true;
      "spotify.showToggleRepeatingButton" = true;
      "spotify.showToggleShufflingButton" = true;
      "spotify.enableLogs" = true;

      "editor.mouseWheelZoom" = true;

      "C_Cpp.autocompleteAddParentheses" = true;
      "C_Cpp.formatting" = "vcFormat";
      "C_Cpp.vcFormat.newLine.closeBraceSameLine.emptyFunction" = true;
      "C_Cpp.vcFormat.newLine.closeBraceSameLine.emptyType" = true;
      "C_Cpp.vcFormat.space.beforeEmptySquareBrackets" = true;
      "C_Cpp.vcFormat.newLine.beforeOpenBrace.block" = "sameLine";
      "C_Cpp.vcFormat.newLine.beforeOpenBrace.function" = "sameLine";
      "C_Cpp.vcFormat.newLine.beforeElse" = false;
      "C_Cpp.vcFormat.newLine.beforeCatch" = false;
      "C_Cpp.vcFormat.newLine.beforeOpenBrace.type" = "sameLine";
      "C_Cpp.vcFormat.space.betweenEmptyBraces" = true;
      "C_Cpp.vcFormat.space.betweenEmptyLambdaBrackets" = true;
      "C_Cpp.vcFormat.indent.caseLabels" = true;
      "C_Cpp.intelliSenseCacheSize" = 2048;
      "C_Cpp.intelliSenseMemoryLimit" = 2048;
      "C_Cpp.default.browse.path" = [
        ''''${workspaceFolder}/**''
      ];
      "C_Cpp.default.cStandard" = "gnu11";
      "C_Cpp.inlayHints.parameterNames.hideLeadingUnderscores" = false;
      "C_Cpp.intelliSenseUpdateDelay" = 500;
      "C_Cpp.workspaceParsingPriority" = "medium";
      "C_Cpp.clang_format_sortIncludes" = true;
      "C_Cpp.doxygen.generatedStyle" = "/**";
    };
    # Keybindings
    keybindings = [
      {
        key = "ctrl+q";
        command = "editor.action.commentLine";
        when = "editorTextFocus && !editorReadonly";
      }
      {
        key = "ctrl+space";
        command = "-editor.action.triggerSuggest";
        when = "editorHasCompletionItemProvider && textInputFocus && !editorReadonly && !suggestWidgetVisible";
      }
      {
        key = "ctrl+space";
        command = "-focusSuggestion";
        when = "suggestWidgetVisible && textInputFocus && !suggestWidgetHasFocusedSuggestion";
      }
      {
        key = "ctrl+space";
        command = "-toggleSuggestionDetails";
        when = "suggestWidgetHasFocusedSuggestion && suggestWidgetVisible && textInputFocus";
      }
      {
        key = "ctrl+space";
        command = "-workbench.action.terminal.sendSequence";
        when = "terminalFocus && terminalShellIntegrationEnabled && !accessibilityModeEnabled && terminalShellType == 'pwsh'";
      }
      {
        key = "ctrl+space";
        command = "-workbench.action.terminal.sendSequence";
        when = "config.terminal.integrated.shellIntegration.suggestEnabled && terminalFocus && terminalShellIntegrationEnabled && !accessibilityModeEnabled && terminalShellType == 'pwsh'";
      }
      {
        key = "ctrl+space";
        command = "python.execInTerminal";
        when = "editorLangId == python";
      }
    ];
  };
}