{ lib, pkgs-unstable, pkgs-stable, username, inputs, hasNvidia, isServer, ... } : let

  catppuccin-qt5ct = pkgs-stable.fetchFromGitHub {
    owner = "catppuccin";
    repo = "qt5ct";
    rev = "main";
    hash = "sha256-wDj6kQ2LQyMuEvTQP6NifYFdsDLT+fMCe3Fxr8S783w=";
  };

  catppuccin-kvantum = pkgs-stable.fetchFromGitHub {
    owner = "catppuccin";
    repo = "Kvantum";
    rev = "main";
    hash = "sha256-V5Upqkil9Q2MeEPtEAemirbJxnEyYcM3Z8jiyz//ccw=";
  };

in {

  programs = {
    nh = {
      enable = true;
      clean.enable = true;
    };

    # Cat alternative
    bat = {
      enable = true;
      config = {
        pager = "less -FR";
      };
    };

    # Monitor of resources
    btop = {
      enable = true;
      package = if hasNvidia then pkgs-stable.btop-cuda else pkgs-stable.btop;
    };

    # Audio visualiser
    cava = {
      enable = true;

      settings = {
        general = {
          framerate = 60;
          sleep_timer = 1;
        };
        input = {
          method = "pulse";
        };
        smoothing = {
          noise_reduction = 0.75;
        };
        output = {
          method = "ncurses";
        };
      }; 
    };

    # Shell extension that manages your environment
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Styling to override stylix
    bat.config.theme = lib.mkForce "Catppuccin Mocha";
    fzf.colors = lib.mkForce {
      "bg+" = "#313244";
    };
  };

  # Foobar2000
  home.file = {
    ".config/beefweb_mpris/config.yaml" = lib.mkIf (!isServer) {
      source = "${pkgs-stable.callPackage ../../packages/foobar2000.nix { inherit pkgs-stable inputs username; }}/share/beefweb_mpris/config.yaml";
    };

    # Kvantum
    ".config/Kvantum/catppuccin-mocha-blue".source = "${catppuccin-kvantum}/themes/catppuccin-mocha-blue";
    ".config/Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=catppuccin-mocha-blue
    '';

    # QT
    ".config/qt5ct/colors/catppuccin-mocha-mauve.conf".source = "${catppuccin-qt5ct}/themes/catppuccin-mocha-blue.conf";
    ".config/qt6ct/colors/catppuccin-mocha-mauve.conf".source = "${catppuccin-qt5ct}/themes/catppuccin-mocha-blue.conf";
    ".config/qt5ct/qt5ct.conf".text = ''
      [Appearance]
      style=kvantum
      custom_palette=true
      color_scheme_path=/home/${username}/.config/qt5ct/colors/catppuccin-mocha-mauve.conf
      [Fonts]
      fixed="JetBrainsMono Nerd Font,12"
      general="DejaVu Sans,12"
    '';
    ".config/qt6ct/qt6ct.conf".text = ''
      [Appearance]
      style=kvantum
      custom_palette=true
      color_scheme_path=/home/${username}/.config/qt6ct/colors/catppuccin-mocha-mauve.conf
      [Fonts]
      fixed="JetBrainsMono Nerd Font,12"
      general="DejaVu Sans,12"
    '';

    ".config/opencode/opencode.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      model = "qwen3.6:35b-a3b-mtp-q4_K_M";
      small_model = "ollama/qwen2.5-coder:7b";
      lsp = true;

      provider = {
        "ollama" = {
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama (local)";
          options = {
            baseURL = "http://localhost:11434/v1";
            apiKey = "ollama";
          };
          models = {
            "qwen3.6:35b-a3b-mtp-q4_K_M" = {
              name = "Qwen3.6 35B";
              limit = {
                context = 262144;
                output = 65536;
              };
            };
            "qwen2.5-coder:7b" = {
              name = "Qwen2.5-Coder 7B";
              limit = {
                context = 262144;
                output = 65536;
              };
            };
          };
        };
      };

      mcp = {
        context7 = {
          type = "remote";
          url = "https://mcp.context7.ai/mcp";
          enabled = true;
        };
      };

      plugin = [
        "opencode-direnv"
        "OpenCodeRAG"
        "opencode-throughput"
        "opencode-simple-notify"
      ];
    };
  };
}
