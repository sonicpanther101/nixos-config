{ pkgs, config, lib, ... }: 
{
  services = {
    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;
    dbus.enable = true;
    fstrim.enable = true;
  };
  services.logind.extraConfig = ''
    # don’t shutdown when power button is short-pressed
    HandlePowerKey=ignore
  '';
  services.swayidle = {
    enable = true;
    events = [
      {
        event = "lock";
        command = "${pkgs.playerctl}/bin/playerctl pause";
      }
      {
        event = "before-sleep";
        command = 'loginctl lock-session $XDG_SESSION_ID';
      }
      {
        event = "before-sleep";
        command =
          "${pkgs.swaylock-effects}/bin/swaylock --screenshot --clock --indicator --indicator-radius 100 --indicator-thickness 7 --effect-blur 7x5 --effect-vignette 0.5:0.5 --ring-color 966C59 --key-hl-color D08770 --line-color 00000000 --inside-color 4C3A32CC --separator-color 2E1E18 --grace 2 --fade-in 0.2";
      }
      {
        event = "lock";
        command =
          "${pkgs.swaylock-effects}/bin/swaylock --screenshot --clock --indicator --indicator-radius 100 --indicator-thickness 7 --effect-blur 7x5 --effect-vignette 0.5:0.5 --ring-color 966C59 --key-hl-color D08770 --line-color 00000000 --inside-color 4C3A32CC --separator-color 2E1E18 --grace 2 --fade-in 0.2";
      }
    ];
  };
}
