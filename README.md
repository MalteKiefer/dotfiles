# dotfiles

Personal Arch Linux / niri compositor setup on a Framework 13 (AMD Ryzen AI 300).

## Stack

| Component        | Tool                              |
| ---------------- | --------------------------------- |
| Compositor       | [niri](https://github.com/YaLTeR/niri) (scrollable-tiling Wayland) |
| Bar              | waybar                            |
| Launcher         | fuzzel                            |
| Terminals        | alacritty (primary), foot         |
| Shell            | fish + starship                   |
| Notifications    | mako                              |
| Login manager    | greetd + tuigreet                 |
| Wallpaper        | swaybg                            |
| Lock             | swaylock                          |
| Power menu       | wlogout                           |
| File manager     | thunar                            |
| Theme            | Catppuccin Mocha + Papirus icons  |
| Cursor           | catppuccin-mocha-dark (AUR)       |
| Font             | JetBrainsMono Nerd Font           |

## Layout

```
.config/
├── alacritty/alacritty.toml
├── fastfetch/config.jsonc
├── fish/config.fish
├── foot/foot.ini
├── fuzzel/fuzzel.ini
├── mako/config
├── niri/config.kdl
├── starship.toml
└── waybar/{config.jsonc,style.css}
.local/bin/
└── mullvad-waybar          # Waybar custom module: Mullvad VPN status
assets/
└── wallpaper.jpg
install.sh                  # Symlink dotfiles into $HOME
```

## Install

```sh
git clone https://github.com/maltekiefer/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer symlinks each config into `$HOME` and backs up any existing files
to `~/.dotfiles-backup-<timestamp>/`.

## Required packages (Arch)

```
# Repo
niri waybar greetd greetd-tuigreet swaybg swaylock swayidle wlogout
mako alacritty foot fuzzel fish starship fastfetch
xdg-desktop-portal-{gtk,gnome} pipewire pipewire-pulse wireplumber
gnome-keyring libsecret polkit-kde-agent
ttf-jetbrains-mono-nerd papirus-icon-theme qt6ct
brightnessctl wl-clipboard grim slurp

# AUR
catppuccin-cursors-mocha xwayland-satellite niriswitcher
```

## Notes

- Keyboard layout: German (`de`).
- Output `eDP-1` scaled to 1.5x (Framework 13 default).
- `Mod` = Super (Windows key).
- `xwayland-satellite` is started by niri so X11 apps (JDownloader, Mullvad GUI)
  work inside the compositor.
- The Mullvad waybar script parses `mullvad status` and emits JSON; works on
  any system with Mullvad installed.
- `~/Bilder/Bildschirmfotos/` is created by `xdg-user-dirs-update` (German locale).
- 1Password SSH agent is wired in `fish/config.fish` via
  `SSH_AUTH_SOCK=$HOME/.1password/agent.sock`.

## License

MIT
