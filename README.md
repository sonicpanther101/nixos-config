## Usage:

### First usage

1. Install  git: 
```bash
nix-shell -p git
```
2. Clone repo: 
```bash
git clone https://www.github.com/sonicpanther101/nixos-config
```
3. Replace hardware config with appropriate host: 
```bash
cp /etc/nixos/hardware-configuration.nix ~/nixos-config/hosts/desktop/
```
4. Rebuild system: 
```bash
sudo nixos-rebuild switch --flake ./nixos-config#desktop
```
5. Reboot: 
```bash
reboot
```

### Normal rebuild

```bash
nh os switch ~/nixos-config/ -H desktop --accept-flake-config
```

## Todo:
- [ ] Get sleeping working
- [ ] autostart hyprland, from there everything else can be started by that
- [ ] Add back all programs from old config
- [ ] Replace all mentions of adam with variable
- [ ] Neovim (telescope and supermavin)
- [ ] Astal working (If libraries translated to c, then use that)

## Browser Setup

1. Install vivaldi
2. Set dark mode regardless of os
3. Set left tabs
4. Set privacy to block trackers and ads
5. Sign in (gets bookmarks, login info and few settings)
6. Download https://github.com/catppuccin/vivaldi/releases/download/1.0.0-ctpv2/Catppuccin.Mocha.Blue.zip
7. Import to themes and replace accent with background, delete background image and set it to solid colour #1e1e2e, Set corner rounding to 4.
8. Remove all speed dials
9. Enable start page navigation, switch to dashboard, then turn back off.
10. Use + button to add widgets (weather, calendar, tasks and privacy stats)
11. Change tab stacking to accordion.
12. Make sure panel is on the left, show panel toggle off, floating, auto close and detect page tile notifications on.
13. Change default search for engine, private and images to brave search.
14. Change break mode shortcut to `Ctrl + space`, remove `copy selected text to note` shortcut.
15. Remove all mouse gestures, add fullscreen on mouse up and break mode on mouse down.
16. add Google calendar account, and check it loads on start page widgets calendar and tasks.