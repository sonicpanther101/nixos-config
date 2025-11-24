## Usage:

### Nixos installation

1. Make sure internet is connected, use nmtui to connect.

2. In the installer select the time zone and keyboard layout, the default should be fine if the installer was started with internet. 

#### Important steps are in codeblocks

```
3. Set name and username, I set both to the same.

4. Set password, disable require strong passwords and check use same password for admin account.
```

5. Choose no desktop.

6. Check allow unfree software.

```
7. Make sure partitions are done correctly, you can lose everything on the drive if messed up. On my laptop I had to create an extra fat32 partition so it didn't overwrite the windows bootloader.
```

8. Install (don't get worriedif it gets stuck on 46% complete)

9. Reboot


### First usage

1. Make sure internet is connected, use nmtui to connect.

2. Install  git: 
```bash
nix-shell -p git
```
3. Clone repo: 
```bash
git clone https://www.github.com/sonicpanther101/nixos-config
```
4. Replace hardware config with appropriate host: 
```bash
cp /etc/nixos/hardware-configuration.nix ~/nixos-config/hosts/<host>/
```
5. Rebuild system: 
```bash
sudo nixos-rebuild switch --flake ./nixos-config#<host>
```
6. Reboot: 
```bash
reboot
```

### Normal rebuild

```bash
nh os switch ~/nixos-config/ -H <host>
```

## Todo:
- [x] Get sleeping working
- [x] Get openrgb to work for sleep
- [x] lock screen
- [x] connect fobar2000 to mpris
- [x] mpris on waybar
- [ ] Dark mode wine for foobar
- [ ] CJK fonts on wine for foobar 
- [x] hyprland workspace keybinds over scrolling
- [ ] Get `my` scripts working
- [ ] remove dirty warning from switch
- [ ] 1 min timeout
- [ ] autostart hyprland, 
- [ ] autostart everything else in hyprland
- [x] Replace all mentions of adam with variable
- [ ] See if all intel graphics drivers are needed
- [ ] Get all folders on syncthing
- [ ] Add back all programs from old config
- [ ] Write vivaldi explicit setup
- [ ] Stop fuzzy cursor
- [ ] Neovim (telescope and supermavin)
- [ ] Astal working or try quickshell (If libraries translated to c, then use that)

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