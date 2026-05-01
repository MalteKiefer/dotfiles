# ─── env ──────────────────────────────────────────────────────────────────
fish_add_path -p $HOME/.local/bin
fish_add_path -p $HOME/.bun/bin
fish_add_path -p $HOME/.cargo/bin
fish_add_path -p $HOME/go/bin

set -gx BUN_INSTALL "$HOME/.bun"
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less
set -gx LESS '-R --mouse'
set -gx MANPAGER 'less -R --use-color -Dd+r -Du+b'
set -gx BAT_THEME "TwoDark"
# 1Password SSH-Agent (after 1password install + login)
set -gx SSH_AUTH_SOCK "$HOME/.1password/agent.sock"

# ─── interactive only ─────────────────────────────────────────────────────
if status is-interactive
    # starship prompt
    if command -q starship
        starship init fish | source
    end

    # modern CLI replacements (alias only if installed)
    command -q eza; and alias ls 'eza --icons --group-directories-first'
    command -q eza; and alias ll 'eza -l --icons --git --group-directories-first'
    command -q eza; and alias la 'eza -la --icons --git --group-directories-first'
    command -q eza; and alias lt 'eza --tree --icons --level=2'
    command -q bat; and alias cat 'bat --paging=never'
    command -q btop; and alias top btop

    # quality-of-life
    alias g git
    alias rg 'rg --hidden --smart-case'
    alias ip 'ip -c'
    alias diff 'diff --color=auto'

    # safety
    alias rm 'rm -i'
    alias cp 'cp -i'
    alias mv 'mv -i'

    # system (Arch / yay)
    alias upd 'yay -Syu --noconfirm'
    alias pacs 'pacman -Ss'
    alias pacq 'pacman -Q'
    alias ports 'ss -tulpn'
    alias myip 'curl -s https://ifconfig.me; echo'

    # vi-mode
    fish_vi_key_bindings

    # zoxide
    command -q zoxide; and zoxide init fish | source

    # fzf key bindings (Ctrl-R history, Ctrl-T file picker)
    command -q fzf; and fzf --fish | source
end

function fish_greeting
    command -q fastfetch; and fastfetch
end
