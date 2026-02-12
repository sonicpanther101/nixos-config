{ lib, pkgs-unstable, pkgs-stable, username, ... } : let 

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

  programs.nh = {
    enable = true;
    clean.enable = true;
  };

  # Temporary notifications daemon to shut grimblast up
  services.mako = {
    enable = true;
    
    # Set NetworkManager notifications to timeout after 3 seconds
    extraConfig = ''
      [app-name="NetworkManager"]
      default-timeout=3000
    '';
  };

  # Cat alternative
  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR";
    };
  };

  # Browser
  programs.chromium = {
    enable = true;
    package = pkgs-unstable.vivaldi;
    extensions = [ "clngdbkpkpeebahjckkjfobafhncgmne" ];
    commandLineArgs = [
      "--enable-features=WebRTCPipeWireCapturer"
      "--ozone-platform=wayland"
    ];
  };

  # Create policy file to allow DoH
  home.file.".config/vivaldi/NativeMessagingHosts/.keep".text = "";
  
  xdg.configFile."chromium/policies/managed/doh.json".text = builtins.toJSON {
    DnsOverHttpsMode = "automatic";  # or "secure" to force DoH
    # DnsOverHttpsTemplates = "https://dns.nextdns.io/176a88";
  };

  # Screen shader
  services.hyprsunset = {
    enable = true;

    settings = {
      profile = [{
        time = "7:30";
        identity = true;
      }

      {
        time = "21:00";
        temperature = 5500;
        gamma = 0.8;
      }];
    };
  };

  # Styling to override stylix
  programs.bat.config.theme = lib.mkForce "Catppuccin Mocha";
  programs.fzf.colors = lib.mkForce {
    "bg+" = "#313244";
  };

  # Kvantum
  home.file.".config/Kvantum/catppuccin-mocha-blue".source = "${catppuccin-kvantum}/themes/catppuccin-mocha-blue";
  home.file.".config/Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=catppuccin-mocha-blue
  '';


  # QT
  home.file.".config/qt5ct/colors/catppuccin-mocha-mauve.conf".source = "${catppuccin-qt5ct}/themes/catppuccin-mocha-blue.conf";
  home.file.".config/qt6ct/colors/catppuccin-mocha-mauve.conf".source = "${catppuccin-qt5ct}/themes/catppuccin-mocha-blue.conf";
  home.file.".config/qt5ct/qt5ct.conf".text = ''
    [Appearance]
    style=kvantum
    custom_palette=true
    color_scheme_path=/home/${username}/.config/qt5ct/colors/catppuccin-mocha-mauve.conf
    [Fonts]
    fixed="JetBrainsMono Nerd Font,12"
    general="DejaVu Sans,12"
  '';
  home.file.".config/qt6ct/qt6ct.conf".text = ''
    [Appearance]
    style=kvantum
    custom_palette=true
    color_scheme_path=/home/${username}/.config/qt6ct/colors/catppuccin-mocha-mauve.conf
    [Fonts]
    fixed="JetBrainsMono Nerd Font,12"
    general="DejaVu Sans,12"
  '';
}