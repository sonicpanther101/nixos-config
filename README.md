## Usage:

### First usage

1. Install  git: `nix-shell -p git`
2. Clone repo: `git clone https://www.github.com/sonicpanther101/nixos-config`
3. Replace hardware config: `cp /etc/nixos/hardware-configuration.nix ~/nixos-config//hosts/desktop/`
4. Rebuild system: `sudo nixos-rebuild --flake switch ./nixos-config#desktop`
5. Reboot: `reboot`

### Normal rebuild

`nh os switch ~/nixos-config/ -H desktop --accept-flake-config`

## Todo:
- [ ] Get sleeping working
- [ ] autostart hyprland, from there everything else can be started by that
- [ ] Add back all programs from old config
- [ ] Replace all mentions of adam with variable
- [ ] Neovim (telescope and supermavin)
- [ ] Astal working (If libraries translated to c, then use that)
