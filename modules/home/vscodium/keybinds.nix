{ ... } : {
programs.vscode.profiles.default.keybindings = [
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
}