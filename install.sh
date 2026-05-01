#!/usr/bin/env bash
# Symlink dotfiles into $HOME. Run from repo root.
# Backs up any existing files to ~/.dotfiles-backup-<timestamp>/.

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

link() {
    local src=$1 dst=$2
    if [[ -e "$dst" || -L "$dst" ]]; then
        mkdir -p "$BACKUP/$(dirname "${dst#$HOME/}")"
        mv "$dst" "$BACKUP/${dst#$HOME/}"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    echo "linked: $dst -> $src"
}

# .config tree
for d in niri waybar alacritty foot fuzzel fastfetch fish mako; do
    [[ -d "$REPO/.config/$d" ]] && link "$REPO/.config/$d" "$HOME/.config/$d"
done
link "$REPO/.config/starship.toml" "$HOME/.config/starship.toml"

# .local/bin scripts
mkdir -p "$HOME/.local/bin"
for f in "$REPO"/.local/bin/*; do
    [[ -f "$f" ]] && link "$f" "$HOME/.local/bin/$(basename "$f")"
done

# Wallpaper
link "$REPO/assets/wallpaper.jpg" "$HOME/.wallpaper.jpg"

# Git config (interactive — overwrite warning)
if [[ -f "$REPO/.gitconfig" ]]; then
    link "$REPO/.gitconfig" "$HOME/.gitconfig"
fi

echo
echo "Done. Backup of overwritten files: $BACKUP"
echo "Re-login or run 'systemctl --user restart waybar mako' to apply."
