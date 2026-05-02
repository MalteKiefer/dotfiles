# dotfiles

Personal Linux desktop setup — a scrollable-tiling Wayland rice for the
**Framework 13 (AMD Ryzen AI 300)** running Arch / EndeavourOS, themed in
**Catppuccin Mocha** end-to-end.

![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)
![Arch / EndeavourOS](https://img.shields.io/badge/distro-Arch%20%2F%20EndeavourOS-1793D1?logo=archlinux&logoColor=white)
![niri](https://img.shields.io/badge/compositor-niri-7c3aed)
![Catppuccin Mocha](https://img.shields.io/badge/theme-Catppuccin%20Mocha-cba6f7)

---

## Stack

| Component        | Tool                                                                |
| ---------------- | ------------------------------------------------------------------- |
| Compositor       | [niri](https://github.com/YaLTeR/niri) (scrollable-tiling Wayland)  |
| Bar              | waybar (vertical left sidebar)                                      |
| Launcher         | fuzzel + rofi                                                       |
| Terminals        | alacritty (primary), foot, kitty                                    |
| Shell            | fish + starship                                                     |
| Notifications    | mako                                                                |
| Login manager    | greetd + tuigreet                                                   |
| Wallpaper        | swaybg                                                              |
| Lock             | gtklock                                                             |
| File manager     | yazi (TUI), thunar (GUI)                                            |
| PDF reader       | zathura                                                             |
| Network          | NetworkManager — `nmtui` in alacritty (no tray applet)              |
| Bluetooth        | bluez + `bluetuith` TUI in alacritty (no blueman)                   |
| VPN              | Mullvad (waybar custom module)                                      |
| Theme            | Catppuccin Mocha + Papirus icons                                    |
| Cursor           | catppuccin-mocha-dark (AUR)                                         |
| Font             | JetBrainsMono Nerd Font                                             |

---

## Highlights

- **Single-source theme** — Catppuccin Mocha palette injected via dedicated
  color files (`alacritty/colors.toml`, `waybar/colors.css`, starship palette
  references) so re-theming touches one file per app.
- **No tray applets** — network and bluetooth are TUI-driven (`nmtui`,
  `bluetuith`) launched directly from waybar clicks. Lighter, faster, no extra
  GTK background processes.
- **Centralised git hooks** — `core.hooksPath` points every repo at
  `~/.config/git/hooks`. The `commit-msg` hook strips AI-generated attribution
  lines from commit messages automatically.
- **Idempotent installer** — `install.sh` symlinks each config into `$HOME`
  and backs up overwrites to `~/.dotfiles-backup-<timestamp>/`.
- **Bootstrap script** — `install-eos.sh` is a staged Arch / EndeavourOS
  post-install script (drivers, network, printer, audio, dev tooling, AUR apps)
  with `--dry-run` and per-stage flags.

---

## Layout

```
.config/
├── alacritty/         # alacritty.toml + colors.toml split
├── fastfetch/         # neofetch replacement
├── fish/              # config.fish + conf.d/, fish_variables
├── foot/              # secondary terminal
├── fuzzel/            # app launcher
├── git/hooks/         # central commit-msg + post-rewrite hooks
├── gtklock/           # lock screen
├── kitty/             # tertiary terminal
├── mako/              # notifications, per-app rules
├── niri/              # compositor: keybinds, output, layout
├── rofi/              # secondary launcher
├── starship.toml      # prompt
├── waybar/            # bar config + modules + colors + style
├── yazi/              # TUI file manager
└── zathura/           # PDF reader

.local/bin/
├── low-battery-notify.sh   # battery alert daemon
└── mediactl                # wpctl + brightnessctl + playerctl wrapper

assets/
└── wallpaper.jpg

.gitconfig             # global git config (centralised hooks)
.gitignore             # global ignore (OS, editors, build, secrets, AI)
install.sh             # symlink dotfiles into $HOME
install-eos.sh         # Arch / EndeavourOS bootstrap (staged, --dry-run)
```

---

## Install

### Dotfiles only

```sh
git clone git@github.com:MalteKiefer/dotfiles ~/Entwicklung/dotfiles
cd ~/Entwicklung/dotfiles
./install.sh
```

The installer symlinks each config into `$HOME` and backs up any existing
files to `~/.dotfiles-backup-<timestamp>/`.

### Full system bootstrap (fresh Arch / EndeavourOS)

```sh
./install-eos.sh --help        # see all stages
./install-eos.sh --dry-run     # preview what would run
./install-eos.sh --all         # everything
```

Stages: `--base --network --printer --audio --bluetooth --dev --apps`.

---

## Required packages

```
# Repo
niri waybar greetd greetd-tuigreet swaybg gtklock swayidle
mako alacritty foot kitty fuzzel rofi fish starship fastfetch yazi zathura
xdg-desktop-portal-{gtk,gnome} pipewire pipewire-pulse wireplumber
gnome-keyring libsecret polkit-gnome
networkmanager bluez bluez-utils
ttf-jetbrains-mono-nerd papirus-icon-theme qt6ct
brightnessctl wl-clipboard grim slurp playerctl wpctl

# AUR
catppuccin-cursors-mocha xwayland-satellite niriswitcher
mullvad-vpn-bin bluetuith-bin
```

---

## Hardware notes (Framework 13 AMD)

- Output `eDP-1` scaled `1.5x` (2256×1504 panel).
- Backlight: `amdgpu_bl1` (waybar `backlight` module — **not** `intel_backlight`).
- Wi-Fi 7 / Bluetooth: MediaTek MT7925 — needs `linux-firmware-mediatek`.
- `xwayland-satellite` is auto-spawned by niri so X11 apps (Android Studio,
  JDownloader, Mullvad GUI) work inside the compositor.
- `DISPLAY=:0` is set explicitly in niri env — required for Java AWT apps,
  which silently die with `null` `DISPLAY`.

---

## Conventions

- **Keyboard layout**: German (`de`).
- **Modifier**: `Mod` = Super (Windows key).
- **Locale**: German — XDG user dirs (`Bilder/Bildschirmfotos/`, etc.).
- **SSH agent**: 1Password — wired conditionally in `fish/config.fish` via
  `SSH_AUTH_SOCK=$HOME/.1password/agent.sock`.
- **Commits**: signed off as `Malte Kiefer <malte.kiefer@mailbox.org>`; the
  central `commit-msg` hook strips any AI co-author / generated-by lines.

---

## License

MIT — see [LICENSE](LICENSE) (or do whatever you want with it; I won't notice).
