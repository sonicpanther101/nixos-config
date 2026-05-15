{ pkgs-unstable, pkgs-stable, config, lib, ... } : {
  imports = [
    ./extensions.nix
    ./keybinds.nix
  ];
  
  programs.vscode = {
    enable = true;
    package = pkgs-unstable.vscodium-fhs;
    mutableExtensionsDir = true;
  };

  home = {
    file."${config.xdg.configHome}/VSCodium/User/settings.json" = {
      text = builtins.toJSON {
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
        "extensions.experimental.affinity" = {
          "asvetliakov.vscode-neovim" = 1;
        };
        "clangd.path" = "/home/adam/.config/VSCodium/User/globalStorage/llvm-vs-code-extensions.vscode-clangd/install/21.1.0/clangd_21.1.0/bin/clangd";
      };
      force = true;
    };

    activation.wakatimeApiKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="${config.xdg.configHome}/VSCodium/User/settings.json"
      secret=$(cat ${config.sops.secrets.wakatime_api_key.path})

      $DRY_RUN_CMD ${pkgs-stable.jq}/bin/jq \
        --arg key "$secret" \
        '."wakaTime.apiKey" = $key' \
        "$settings" > /tmp/vscodium-settings.json

      $DRY_RUN_CMD mv /tmp/vscodium-settings.json "$settings"
    '';
  };
}