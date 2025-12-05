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

### My-install Rebuild

#### Setup

1. Change to ssh
```bash
cd ~/nixos-config
git remote set-url origin git@github.com:sonicpanther101/nixos-config.git
```
2. Then make sure you have SSH keys set up:

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy the public key (ignore the email)
cat ~/.ssh/id_ed25519.pub
```
3. Add the public key to GitHub: Settings → SSH and GPG keys → New SSH key

#### Usage
```bash
my-install
```

### Errors

- Files already in place home manager wants to control
```
warning: the following units failed: home-manager-adam.service
Error: 
   0: Activation (test) failed
   1: Activating configuration (exit status Exited(4))
```

- If nemo confirmations have dark text and background, change colour scheme to catppuccin mocha in qt5ct and qt6ct

## Todo:
- [x] Get sleeping working
- [x] Get openrgb to work for sleep
- [x] lock screen
- [x] connect fobar2000 to mpris
- [x] mpris on waybar
- [ ] Dark mode wine for foobar
- [ ] CJK fonts on wine for foobar 
- [x] hyprland workspace keybinds over scrolling
- [x] Get `my` scripts working
- [x] Make my-install change depending on host/username and commit changes before nh
- [x] remove dirty warning from switch
- [x] 1 min timeout
- [x] Install openRGB udev rules
- [x] Get fans RGB working
- [x] autostart hyprland, 
- [x] autostart everything else in hyprland
- [x] fix hyprlock not working first try
- [x] Add other drives to auto mount in hardware-config
- [x] Add upower and auto-cpufreq services for laptop
- [x] Change my-shutdown to turn off rgb
- [x] Set up mime for default apps
- [x] Set up vscode-neovim as transition to neovim
- [x] Wakatime
- [x] Get l and ll working
- [x] Back up stylus to this repo (did it with integrated google drive)
- [x] Add gnupg for security
- [x] Replace all mentions of adam with variable
- [ ] See if all intel graphics drivers are needed
- [x] Get all folders on syncthing
- [ ] Tagscanner and mp3tag
- [ ] Get VSCodium settings nixified
- [ ] Change bootloader theme to my fork
- [x] Set up bluetooth
- [ ] Add back all programs from old config
- [ ] Add floating terminal
- [ ] Write vivaldi explicit setup
- [ ] Stop fuzzy cursor
- [ ] Customise starship
- [ ] Fill in components list in readme
- [ ] Typst to use instead of latex
- [ ] Neovim (telescope and supermavin)
- [ ] Astal working or try quickshell (If libraries translated to c, then use that)
- [ ] Get HDR working

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
14. Change break mode shortcut to `Ctrl + space`, remove `copy selected text to note` shortcut and remove `exit` shortcut.
15. Remove all mouse gestures, add fullscreen on mouse up and break mode on mouse down.
16. add Google calendar account, and check it loads on start page widgets calendar and tasks.
17. Change weather location to correct location, select kmph over m/s
18. Remove toolbar widgets; notes, translate, reading list, mail, contacts, calendar, tasks, feeds, vivaldi social, vivaldi help, wikipedia, vpn, the gap between search and vpn, vivaldi share.
19. Add toolbar widgets; status bar's zoom and page tiler to the top bar, google translate, discord, proton and vivaldi settings to panel.


## TODO: 📓 Components
|                             | NixOS + Hyprland                                                                              |
| --------------------------- | :---------------------------------------------------------------------------------------------:
| **Window Manager**          | [Hyprland][Hyprland] |
| **Bar**                     | [Waybar][Waybar] |
| **Application Launcher**    | [wofi][wofi] |
| **Notification Daemon**     | [swaync][swaync] |
| **Terminal Emulator**       | [Ghostty][Ghostty] |
| **Shell**                   | [zsh][zsh] + [powerlevel10k][powerlevel10k] |
| **Text Editor**             | [VSCodium][VSCodium] + [Neovim][Neovim] |
| **network management tool** | [NetworkManager][NetworkManager] + [network-manager-applet][network-manager-applet] |
| **System resource monitor** | [Btop][Btop] |
| **File Manager**            | [nemo][nemo] + [yazi][yazi] |
| **Fonts**                   | [Maple Mono][Maple Mono] |
| **Color Scheme**            | [Gruvbox Dark Hard][Gruvbox] |
| **GTK theme**               | [Colloid gtk theme][Colloid gtk theme] |
| **Cursor**                  | [Bibata-Modern-Ice][Bibata-Modern-Ice] |
| **Icons**                   | [Papirus-Dark][Papirus-Dark] |
| **Lockscreen**              | [Hyprlock][Hyprlock] + [Swaylock-effects][Swaylock-effects] |
| **Image Viewer**            | [imv][imv] |
| **Media Player**            | [mpv][mpv] |
| **Music Player**            | [audacious][audacious] |
| **Screenshot Software**     | [grimblast][grimblast] |
| **Screen Recording**        | [wf-recorder][wf-recorder] + [OBS][OBS] |
| **Clipboard**               | [wl-clip-persist][wl-clip-persist] |
| **Color Picker**            | [hyprpicker][hyprpicker] |

<!-- Links -->
[Hyprland]: https://github.com/hyprwm/Hyprland
[Ghostty]: https://ghostty.org/
[powerlevel10k]: https://github.com/romkatv/powerlevel10k
[Waybar]: https://github.com/Alexays/Waybar
[rofi]: https://github.com/lbonn/rofi
[Btop]: https://github.com/aristocratos/btop
[nemo]: https://github.com/linuxmint/nemo/
[yazi]: https://github.com/sxyazi/yazi
[zsh]: https://ohmyz.sh/
[Swaylock-effects]: https://github.com/mortie/swaylock-effects
[Hyprlock]: https://github.com/hyprwm/hyprlock
[audacious]: https://audacious-media-player.org/
[mpv]: https://github.com/mpv-player/mpv
[VSCodium]:https://vscodium.com/
[Neovim]: https://github.com/neovim/neovim
[grimblast]: https://github.com/hyprwm/contrib
[imv]: https://sr.ht/~exec64/imv/
[swaync]: https://github.com/ErikReider/SwayNotificationCenter
[Maple Mono]: https://github.com/subframe7536/maple-font
[NetworkManager]: https://wiki.gnome.org/Projects/NetworkManager
[network-manager-applet]: https://gitlab.gnome.org/GNOME/network-manager-applet/
[wl-clip-persist]: https://github.com/Linus789/wl-clip-persist
[wf-recorder]: https://github.com/ammen99/wf-recorder
[hyprpicker]: https://github.com/hyprwm/hyprpicker
[Gruvbox]: https://github.com/morhetz/gruvbox
[Papirus-Dark]: https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
[Bibata-Modern-Ice]: https://www.gnome-look.org/p/1197198
[maxfetch]: https://github.com/jobcmax/maxfetch
[Colloid gtk theme]: https://github.com/vinceliuice/Colloid-gtk-theme
[OBS]: https://obsproject.com/