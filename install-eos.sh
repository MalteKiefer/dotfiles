#!/usr/bin/env bash
# EndeavourOS / Arch post-install script — staged.
#
# Usage:  install-eos.sh [STAGE ...]
# See:    install-eos.sh --help

set -Eeuo pipefail

# ─── logging ────────────────────────────────────────────────────────────────
LOG_DIR="$HOME/.local/state/install-eos"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
ln -sfn "$LOG_FILE" "$LOG_DIR/latest.log"
exec > >(tee -a "$LOG_FILE") 2>&1

ts()      { date '+%Y-%m-%d %H:%M:%S'; }
log()     { printf '\033[1;34m[%s] [INFO ]\033[0m %s\n'  "$(ts)" "$*"; }
warn()    { printf '\033[1;33m[%s] [WARN ]\033[0m %s\n'  "$(ts)" "$*"; }
err()     { printf '\033[1;31m[%s] [ERROR]\033[0m %s\n'  "$(ts)" "$*" >&2; }
ok()      { printf '\033[1;32m[%s] [ OK  ]\033[0m %s\n'  "$(ts)" "$*"; }
section() { printf '\n\033[1;35m[%s] === %s ===\033[0m\n' "$(ts)" "$*"; }

FAILED_PKGS=()
FAILED_UNITS=()
SKIPPED=()
INSTALL_CLAUDE_VIA_NPM=0

trap 'err "Aborted at line $LINENO (exit=$?). Log: $LOG_FILE"' ERR
trap 'log "Log written to $LOG_FILE"' EXIT

# ─── help ───────────────────────────────────────────────────────────────────
HELP_TEXT='install-eos.sh — staged Arch/EndeavourOS post-install

USAGE
    install-eos.sh [STAGE ...]

STAGES
    --all            Run every stage (default if no flags given)
    --base           CLI base + dev tools (fish, git, npm, php, neovim, eza, etc.)
    --driver         Framework 13 AMD HW drivers (amd-ucode, MT7925 fw, mesa,
                     vulkan-radeon, sof-firmware, fprintd, iio-sensor-proxy,
                     power-profiles-daemon)
    --desktop        niri compositor stack + waybar + xdg-desktop-portal +
                     mako + thunar + alacritty + media viewers + obsidian
    --network        NetworkManager + OpenVPN + Bluetooth + Mullvad VPN
    --printer        CUPS stack + foomatic full + ghostscript + hplip +
                     Brother/Epson vendor drivers from AUR
    --apps           AUR desktop apps (brave, chrome, slack, spotify,
                     1password, jdownloader, android-studio, filebot,
                     filen-desktop, claude-code)
    --config         Host config (hostname=pinetree, fish default shell,
                     systemd services, NTP, /etc/hosts, group memberships)

GENERAL
    --help, -h       Show this help and exit
    --dry-run        Print what would be installed; no changes
    --no-update      Skip pacman -Syu (faster re-runs of single stages)

EXAMPLES
    install-eos.sh                       # run everything
    install-eos.sh --driver              # only Framework HW drivers
    install-eos.sh --printer --config    # printers + system config
    install-eos.sh --base --desktop --network
    install-eos.sh --dry-run --all       # preview full run

NOTES
    Run as a normal user with sudo rights. Do NOT run as root.
    Logs: ~/.local/state/install-eos/latest.log
    yay is bootstrapped automatically if missing.
'

# ─── arg parsing ────────────────────────────────────────────────────────────
DO_BASE=0; DO_DRIVER=0; DO_DESKTOP=0; DO_NETWORK=0
DO_PRINTER=0; DO_APPS=0; DO_CONFIG=0
DRY_RUN=0; SKIP_UPDATE=0; ANY_STAGE=0

while (( $# > 0 )); do
  case "$1" in
    -h|--help)    echo "$HELP_TEXT"; exit 0 ;;
    --all)        DO_BASE=1; DO_DRIVER=1; DO_DESKTOP=1; DO_NETWORK=1
                  DO_PRINTER=1; DO_APPS=1; DO_CONFIG=1; ANY_STAGE=1 ;;
    --base)       DO_BASE=1;    ANY_STAGE=1 ;;
    --driver|--drivers) DO_DRIVER=1; ANY_STAGE=1 ;;
    --desktop)    DO_DESKTOP=1; ANY_STAGE=1 ;;
    --network)    DO_NETWORK=1; ANY_STAGE=1 ;;
    --printer|--printing) DO_PRINTER=1; ANY_STAGE=1 ;;
    --apps)       DO_APPS=1;    ANY_STAGE=1 ;;
    --config)     DO_CONFIG=1;  ANY_STAGE=1 ;;
    --dry-run)    DRY_RUN=1 ;;
    --no-update)  SKIP_UPDATE=1 ;;
    *)            err "Unknown option: $1"; echo; echo "$HELP_TEXT"; exit 2 ;;
  esac
  shift
done

# Default = run all
if (( ANY_STAGE == 0 )); then
  DO_BASE=1; DO_DRIVER=1; DO_DESKTOP=1; DO_NETWORK=1
  DO_PRINTER=1; DO_APPS=1; DO_CONFIG=1
fi

# ─── package lists per stage ────────────────────────────────────────────────

REPO_BASE=(
  wget curl git fish neovim vim rsync starship eza bat
  ripgrep fd fzf zoxide direnv
  ttf-jetbrains-mono-nerd
  github-cli
  nodejs npm yarn
  php composer
  sqlite
  dbeaver
)

REPO_DRIVER=(
  amd-ucode
  linux-firmware
  linux-firmware-mediatek      # MT7925 Wi-Fi 7 + Bluetooth firmware
  sof-firmware                 # Sound Open Firmware
  alsa-firmware alsa-ucm-conf
  mesa
  vulkan-radeon vulkan-icd-loader
  libva-mesa-driver mesa-vdpau
  power-profiles-daemon
  iio-sensor-proxy
  fprintd libfprint
  android-udev
)

REPO_DESKTOP=(
  niri waybar
  # Login manager (TUI greeter, Wayland-friendly, no DM bloat)
  greetd greetd-tuigreet
  # Wallpaper / lock / power menu / idle handling
  swaybg swaylock swayidle wlogout
  # Screen sharing / Wayland portals (gnome portal handles ScreenCast for niri)
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome
  # Audio + screen-share pipeline (PipeWire is ScreenCast transport on Wayland)
  pipewire pipewire-pulse pipewire-alsa pipewire-jack
  wireplumber gst-plugin-pipewire libpipewire
  # Secrets / SSH agent / GNOME Keyring (niri config spawns this)
  gnome-keyring libsecret seahorse
  # Mixer
  pavucontrol
  # Notifications
  mako libnotify
  # File manager + thumbnailers + mounts
  thunar thunar-volman thunar-archive-plugin tumbler gvfs gvfs-mtp
  yazi
  # Terminals
  alacritty kitty
  # Launchers
  rofi fuzzel
  # Lock screen
  gtklock
  # Media keys + battery notifier deps
  playerctl acpi
  # Media + viewers
  mpv
  zathura zathura-pdf-mupdf
  imv
  obsidian
  element-desktop
  # Screen recording / sharing tools
  wf-recorder
  # Polkit auth agent — GNOME variant (path matches niri config)
  polkit-gnome
  # Theming
  qt6ct papirus-icon-theme
  # German locale folder names (~/Bilder, ~/Dokumente …)
  xdg-user-dirs
  # Misc helpers
  brightnessctl
  wl-clipboard
  grim slurp
  qt5-wayland qt6-wayland
)

AUR_DESKTOP=(
  niriswitcher                # Alt-Tab-style window switcher for niri
  xwayland-satellite          # XWayland for niri (X11 apps: jdownloader, mullvad-gui)
  catppuccin-cursors-mocha    # cursor theme referenced in niri config
)

REPO_NETWORK=(
  networkmanager networkmanager-openvpn openvpn
  network-manager-applet
  bluez bluez-utils
)

REPO_PRINTER=(
  cups cups-filters cups-pdf cups-browsed system-config-printer
  ghostscript gutenprint
  foomatic-db foomatic-db-engine foomatic-db-ppds
  foomatic-db-nonfree foomatic-db-nonfree-ppds
  foomatic-db-gutenprint-ppds
  hplip python-pyqt5
  avahi nss-mdns
)

AUR_NETWORK=( mullvad-vpn-bin bluetuith-bin )

AUR_PRINTER=(
  brother-mfc-l3770cdw
  brother-mfc-l3750cdw
  epson-inkjet-printer-am-c4000
)

AUR_APPS=(
  jdownloader2
  1password 1password-cli
  brave-bin
  google-chrome
  slack-desktop
  android-studio
  filebot
  filen-desktop-bin
  spotify
  claude-code
  flutter
)

# ─── helpers ────────────────────────────────────────────────────────────────
run_or_dry() {
  if (( DRY_RUN )); then
    log "[dry-run] would run: $*"
  else
    "$@"
  fi
}

install_repo() {
  local stage=$1; shift
  local pkgs=("$@")
  (( ${#pkgs[@]} == 0 )) && return 0
  log "[$stage] validating ${#pkgs[@]} repo packages…"
  local missing=() valid=()
  for p in "${pkgs[@]}"; do
    if pacman -Si "$p" >/dev/null 2>&1; then
      valid+=("$p")
    else
      missing+=("$p")
      SKIPPED+=("repo:$p ($stage, not in DB)")
    fi
  done
  (( ${#missing[@]} > 0 )) && warn "[$stage] not in pacman DB: ${missing[*]}"

  if (( DRY_RUN )); then
    log "[dry-run] [$stage] pacman -S --needed ${valid[*]}"
    return 0
  fi
  if sudo pacman -S --needed --noconfirm "${valid[@]}"; then
    ok "[$stage] repo install complete (${#valid[@]} pkgs)"
  else
    warn "[$stage] batch install failed — retrying per-package"
    for p in "${valid[@]}"; do
      sudo pacman -S --needed --noconfirm "$p" || {
        FAILED_PKGS+=("repo:$p ($stage)")
        warn "FAILED repo: $p"
      }
    done
  fi
}

install_aur() {
  local stage=$1; shift
  local pkgs=("$@")
  (( ${#pkgs[@]} == 0 )) && return 0
  if (( DRY_RUN )); then
    log "[dry-run] [$stage] yay -S ${pkgs[*]}"
    return 0
  fi

  # claude-code: AUR name varies — handle here so it benefits all stages.
  local resolved=()
  for p in "${pkgs[@]}"; do
    if [[ "$p" == "claude-code" ]] && ! yay -Si claude-code >/dev/null 2>&1; then
      if yay -Si claude-code-bin >/dev/null 2>&1; then
        warn "claude-code -> claude-code-bin"
        resolved+=("claude-code-bin")
      else
        warn "claude-code missing in AUR — will install via npm later"
        INSTALL_CLAUDE_VIA_NPM=1
        SKIPPED+=("aur:claude-code ($stage, falling back to npm)")
        continue
      fi
    else
      resolved+=("$p")
    fi
  done

  for p in "${resolved[@]}"; do
    log "[$stage] → $p"
    if yay -S --needed --noconfirm --sudoloop \
          --answerdiff=None --answerclean=None --answeredit=None \
          --removemake --cleanafter "$p"; then
      ok "[$stage] $p"
    else
      FAILED_PKGS+=("aur:$p ($stage)")
      err "[$stage] AUR build FAILED: $p"
    fi
  done
}

enable_unit() {
  local unit=$1
  if ! systemctl list-unit-files --no-legend "$unit" 2>/dev/null | grep -q "^$unit"; then
    warn "unit $unit not present, skipping"
    return
  fi
  if (( DRY_RUN )); then
    log "[dry-run] would: systemctl enable --now $unit"
    return
  fi
  if sudo systemctl enable --now "$unit" >/dev/null 2>&1; then
    ok "enabled $unit"
  else
    err "enable --now failed for $unit"
    FAILED_UNITS+=("$unit")
  fi
}

verify_unit() {
  local unit=$1
  (( DRY_RUN )) && return
  if ! systemctl list-unit-files --no-legend "$unit" 2>/dev/null | grep -q "^$unit"; then
    return
  fi
  if systemctl is-active --quiet "$unit"; then
    ok "running: $unit"
  elif systemctl is-enabled --quiet "$unit" 2>/dev/null; then
    warn "$unit enabled but inactive (on-demand or next boot)"
  else
    err "$unit neither active nor enabled"
    FAILED_UNITS+=("$unit")
  fi
}

# ─── preflight ──────────────────────────────────────────────────────────────
section "preflight"

if [[ $EUID -eq 0 ]]; then
  err "Run as normal user, not root. Sudo invoked when needed."
  exit 1
fi
if [[ ! -f /etc/arch-release ]]; then
  err "Not an Arch-based system (/etc/arch-release missing)."
  exit 1
fi
ok "Arch-based system detected"
command -v sudo >/dev/null 2>&1 || { err "sudo not installed"; exit 1; }

if (( DRY_RUN )); then
  warn "DRY-RUN mode: no changes will be made"
else
  sudo -v || { err "sudo authentication failed"; exit 1; }
  ok "sudo OK"
  ( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
fi

# Stages selected
SELECTED=()
(( DO_BASE ))    && SELECTED+=(base)
(( DO_DRIVER ))  && SELECTED+=(driver)
(( DO_DESKTOP )) && SELECTED+=(desktop)
(( DO_NETWORK )) && SELECTED+=(network)
(( DO_PRINTER )) && SELECTED+=(printer)
(( DO_APPS ))    && SELECTED+=(apps)
(( DO_CONFIG ))  && SELECTED+=(config)
log "Stages: ${SELECTED[*]}"

# yay bootstrap if any AUR stage selected
need_yay=0
(( DO_DESKTOP )) && need_yay=1
(( DO_NETWORK )) && need_yay=1
(( DO_PRINTER )) && need_yay=1
(( DO_APPS ))    && need_yay=1
if (( need_yay )) && ! command -v yay >/dev/null 2>&1; then
  if (( DRY_RUN )); then
    warn "[dry-run] would bootstrap yay-bin"
  else
    warn "yay missing — bootstrapping yay-bin"
    sudo pacman -S --needed --noconfirm base-devel git
    TMP=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$TMP/yay-bin"
    ( cd "$TMP/yay-bin" && makepkg -si --noconfirm )
    rm -rf "$TMP"
    ok "yay installed"
  fi
fi
if command -v yay >/dev/null 2>&1; then
  log "yay: $(yay --version | head -1)"
fi

FREE_KB=$(df --output=avail -k / | tail -1)
(( FREE_KB < 10*1024*1024 )) && warn "<10 GB free on /. AUR builds may fail."

# ─── system update ──────────────────────────────────────────────────────────
if (( SKIP_UPDATE == 0 )); then
  section "system update"
  log "Refreshing archlinux-keyring first"
  run_or_dry sudo pacman -S --noconfirm --needed archlinux-keyring
  warn "If kernel updates, reboot before launching Wayland sessions."
  warn "Continuing in 5s — Ctrl+C to abort."
  (( DRY_RUN )) || sleep 5
  run_or_dry sudo pacman -Syu --noconfirm
else
  warn "--no-update: skipping pacman -Syu"
fi

# ─── stages ─────────────────────────────────────────────────────────────────

if (( DO_BASE )); then
  section "stage: base"
  install_repo base "${REPO_BASE[@]}"
fi

if (( DO_DRIVER )); then
  section "stage: driver (Framework 13 AMD)"
  install_repo driver "${REPO_DRIVER[@]}"
fi

if (( DO_DESKTOP )); then
  section "stage: desktop (niri stack)"
  install_repo desktop "${REPO_DESKTOP[@]}"
  install_aur  desktop "${AUR_DESKTOP[@]}"
fi

if (( DO_NETWORK )); then
  section "stage: network"
  install_repo network "${REPO_NETWORK[@]}"
  install_aur  network "${AUR_NETWORK[@]}"
fi

if (( DO_PRINTER )); then
  section "stage: printer"
  install_repo printer "${REPO_PRINTER[@]}"
  install_aur  printer "${AUR_PRINTER[@]}"
fi

if (( DO_APPS )); then
  section "stage: apps"
  install_aur apps "${AUR_APPS[@]}"
  if (( INSTALL_CLAUDE_VIA_NPM )); then
    section "claude-code via npm"
    if command -v npm >/dev/null 2>&1; then
      run_or_dry sudo npm install -g @anthropic-ai/claude-code \
        || FAILED_PKGS+=("npm:@anthropic-ai/claude-code")
    else
      warn "npm missing — skipping claude-code"
    fi
  fi
fi

# ─── config stage ───────────────────────────────────────────────────────────
if (( DO_CONFIG )); then
  section "stage: config — hostname"
  TARGET_HOST="pinetree"
  CURRENT_HOST=$(hostnamectl --static 2>/dev/null || hostname)
  if [[ "$CURRENT_HOST" == "$TARGET_HOST" ]]; then
    ok "hostname already $TARGET_HOST"
  else
    log "$CURRENT_HOST -> $TARGET_HOST"
    run_or_dry sudo hostnamectl set-hostname "$TARGET_HOST"
    ok "hostname set"
  fi
  if ! grep -qE "^127\.0\.1\.1\s+$TARGET_HOST" /etc/hosts; then
    log "adding 127.0.1.1 -> $TARGET_HOST to /etc/hosts"
    if (( DRY_RUN )); then
      log "[dry-run] would append /etc/hosts entry"
    else
      echo "127.0.1.1	$TARGET_HOST.localdomain $TARGET_HOST" \
        | sudo tee -a /etc/hosts >/dev/null
      ok "/etc/hosts updated"
    fi
  fi

  section "stage: config — greetd"
  GREETD_CONF='[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --asterisks --sessions /usr/share/wayland-sessions:/usr/share/xsessions --greeting '"'"'Willkommen, Malte'"'"' --cmd niri-session"
user = "greeter"
'
  if [[ -f /etc/greetd/config.toml ]] && \
     diff -q <(printf '%s' "$GREETD_CONF") /etc/greetd/config.toml >/dev/null 2>&1; then
    ok "greetd config already current"
  else
    if (( DRY_RUN )); then
      log "[dry-run] would write /etc/greetd/config.toml"
    else
      sudo install -d -m 755 /etc/greetd
      [[ -f /etc/greetd/config.toml ]] && \
        sudo cp -a /etc/greetd/config.toml \
          "/etc/greetd/config.toml.bak.$(date +%s)"
      printf '%s' "$GREETD_CONF" | sudo tee /etc/greetd/config.toml >/dev/null
      sudo chmod 644 /etc/greetd/config.toml
      ok "greetd config written (backup of previous saved if existed)"
    fi
  fi

  section "stage: config — services"
  enable_unit NetworkManager.service
  enable_unit bluetooth.service
  enable_unit mullvad-daemon.service
  enable_unit systemd-timesyncd.service
  run_or_dry sudo timedatectl set-ntp true
  enable_unit cups.service
  enable_unit cups.socket
  enable_unit cups-browsed.service
  enable_unit avahi-daemon.service
  enable_unit fstrim.timer
  enable_unit power-profiles-daemon.service
  enable_unit iio-sensor-proxy.service
  # Display manager — disable any conflicting DMs first
  for dm in sddm gdm lightdm lxdm; do
    if systemctl is-enabled --quiet "$dm.service" 2>/dev/null; then
      warn "disabling conflicting DM: $dm"
      run_or_dry sudo systemctl disable --now "$dm.service" || true
    fi
  done
  enable_unit greetd.service

  # Run xdg-user-dirs to create localized folders (Bilder, Dokumente, …)
  if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    run_or_dry xdg-user-dirs-update
    ok "xdg-user-dirs updated"
  fi

  # nss-mdns — printer/.local discovery
  if grep -q '^hosts:' /etc/nsswitch.conf \
     && ! grep -E '^hosts:.*mdns_minimal' /etc/nsswitch.conf >/dev/null; then
    log "patching /etc/nsswitch.conf for mdns_minimal"
    if (( DRY_RUN == 0 )); then
      sudo sed -i.bak -E \
        's/^(hosts:\s*)(.*)$/\1mdns_minimal [NOTFOUND=return] \2/' \
        /etc/nsswitch.conf
      ok "nsswitch.conf updated"
    fi
  fi

  # group memberships
  for grp in lp sys onepassword-cli; do
    if getent group "$grp" >/dev/null \
       && ! id -nG "$USER" | tr ' ' '\n' | grep -qx "$grp"; then
      run_or_dry sudo usermod -aG "$grp" "$USER" \
        && ok "added $USER to $grp"
    fi
  done

  # default shell
  FISH_BIN="$(command -v fish || true)"
  if [[ -n "$FISH_BIN" ]]; then
    if ! grep -qx "$FISH_BIN" /etc/shells; then
      run_or_dry bash -c "echo '$FISH_BIN' | sudo tee -a /etc/shells >/dev/null"
    fi
    CUR_SHELL=$(getent passwd "$USER" | cut -d: -f7)
    if [[ "$CUR_SHELL" == "$FISH_BIN" ]]; then
      ok "default shell already $FISH_BIN"
    else
      run_or_dry sudo chsh -s "$FISH_BIN" "$USER" \
        && ok "default shell -> $FISH_BIN (next login)"
    fi
  fi

  section "stage: config — verify services"
  for u in NetworkManager.service bluetooth.service systemd-timesyncd.service \
           cups.service avahi-daemon.service fstrim.timer \
           power-profiles-daemon.service greetd.service; do
    verify_unit "$u"
  done
  verify_unit mullvad-daemon.service || true
  (( DRY_RUN )) || { log "Time sync status:"; timedatectl status | sed 's/^/    /'; }
fi

# ─── HW sanity (driver stage only) ──────────────────────────────────────────
if (( DO_DRIVER )); then
  section "Framework HW sanity"
  SYS_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")
  SYS_PRODUCT=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
  log "Detected: $SYS_VENDOR — $SYS_PRODUCT"
  if [[ "$SYS_VENDOR" == "Framework" ]]; then
    ok "Framework laptop confirmed"
    if lspci -k 2>/dev/null | grep -A3 'MEDIATEK.*MT7925' \
       | grep -q 'Kernel driver in use: mt7925e'; then
      ok "MT7925 Wi-Fi 7 driver loaded"
    else
      warn "MT7925 driver not yet loaded — reboot required"
    fi
    if lspci -k 2>/dev/null | grep -A3 -iE '(VGA|Display).*AMD' \
       | grep -q 'Kernel driver in use: amdgpu'; then
      ok "amdgpu driver loaded"
    else
      warn "amdgpu not yet loaded — reboot required"
    fi
  else
    warn "Not a Framework laptop ($SYS_VENDOR) — driver pkgs may be unused"
  fi
fi

# ─── summary ────────────────────────────────────────────────────────────────
section "summary"
log "Log: $LOG_FILE"
log "Stages run: ${SELECTED[*]}"
(( DRY_RUN )) && warn "DRY-RUN — nothing was changed."

EXIT_CODE=0

if (( ${#SKIPPED[@]} > 0 )); then
  warn "Skipped (${#SKIPPED[@]}):"
  printf '  - %s\n' "${SKIPPED[@]}"
fi

if (( ${#FAILED_PKGS[@]} > 0 )); then
  err "Failed packages (${#FAILED_PKGS[@]}):"
  printf '  - %s\n' "${FAILED_PKGS[@]}"
  EXIT_CODE=1
else
  ok "All requested packages installed."
fi

if (( ${#FAILED_UNITS[@]} > 0 )); then
  err "Failed/inactive units (${#FAILED_UNITS[@]}):"
  printf '  - %s\n' "${FAILED_UNITS[@]}"
  EXIT_CODE=1
fi

cat <<EOF

Next steps:
  • REBOOT to load: amdgpu, mt7925e, sof audio, ucode, group memberships,
    fish login shell.
  • niri config: spawn-at-startup "mako" for notifications.
  • Add printer:           system-config-printer  (or http://localhost:631)
  • Mullvad login:         mullvad account login
  • GitHub auth:           gh auth login
  • Claude:                claude login
  • Fingerprint:           fprintd-enroll
  • Power profile:         powerprofilesctl set balanced|performance|power-saver

Re-run individual stages anytime:
  install-eos.sh --driver
  install-eos.sh --printer --no-update
  install-eos.sh --help

EOF

exit "$EXIT_CODE"
