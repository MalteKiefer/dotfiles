# ─── env ──────────────────────────────────────────────────────────────────
fish_add_path -p $HOME/.local/bin
fish_add_path -p $HOME/.bun/bin
fish_add_path -p $HOME/.cargo/bin
fish_add_path -p $HOME/go/bin

set -gx BUN_INSTALL "$HOME/.bun"
set -gx GOPATH "$HOME/go"
set -gx CARGO_HOME "$HOME/.cargo"

# Android SDK (Android Studio default ~/Android/Sdk)
set -gx ANDROID_HOME "$HOME/Android/Sdk"
set -gx ANDROID_SDK_ROOT "$ANDROID_HOME"
set -gx ANDROID_USER_HOME "$HOME/.android"
fish_add_path -a "$ANDROID_HOME/cmdline-tools/latest/bin"
fish_add_path -a "$ANDROID_HOME/platform-tools"
fish_add_path -a "$ANDROID_HOME/emulator"

set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less
set -gx LESS '-R --mouse'
set -gx MANROFFOPT '-c'
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
set -gx BAT_THEME "Catppuccin Mocha"
set -gx GPG_TTY (tty)

# 1Password SSH-Agent — only if socket exists
if test -S "$HOME/.1password/agent.sock"
    set -gx SSH_AUTH_SOCK "$HOME/.1password/agent.sock"
end

# ─── greeting off ─────────────────────────────────────────────────────────
set -U fish_greeting ""

# ─── interactive only ─────────────────────────────────────────────────────
if status is-interactive
    # starship prompt
    command -q starship; and starship init fish | source

    # vi-mode (block cursor everywhere)
    set -U fish_key_bindings fish_vi_key_bindings
    function fish_mode_prompt; end

    # zoxide
    command -q zoxide; and zoxide init fish | source

    # fzf key bindings (Ctrl-R history, Ctrl-T file picker)
    command -q fzf; and fzf --fish | source

    # direnv
    command -q direnv; and direnv hook fish | source

    # bun completions
    test -s "$BUN_INSTALL/_bun"; and source "$BUN_INSTALL/_bun"
end

# ─── functions ────────────────────────────────────────────────────────────
function mkcd --description 'mkdir -p + cd'
    mkdir -p $argv[1]; and cd $argv[1]
end

function backup --argument filename
    cp $filename $filename.bak
end

function extract --description 'extract any archive'
    set f $argv[1]
    if not test -f $f; echo "'$f' not a file"; return 1; end
    switch $f
        case '*.tar.bz2' '*.tbz2'; tar xjf $f
        case '*.tar.gz' '*.tgz';   tar xzf $f
        case '*.tar.xz' '*.txz';   tar xJf $f
        case '*.tar.zst';          tar --zstd -xf $f
        case '*.tar';              tar xvf $f
        case '*.bz2';              bunzip2 $f
        case '*.gz';               gunzip $f
        case '*.rar';              unrar x $f
        case '*.zip';              unzip $f
        case '*.Z';                uncompress $f
        case '*.7z';               7z x $f
        case '*';                  echo "no extractor for '$f'"; return 1
    end
end

# !! and !$ vi-mode helpers
function __history_previous_command
    switch (commandline -t)
        case "!"; commandline -t $history[1]; commandline -f repaint
        case "*"; commandline -i !
    end
end
function __history_previous_command_arguments
    switch (commandline -t)
        case "!"; commandline -t ""; commandline -f history-token-search-backward
        case "*"; commandline -i '$'
    end
end
bind ! __history_previous_command
bind '$' __history_previous_command_arguments

# ─── aliases (interactive only) ───────────────────────────────────────────
if status is-interactive
    # eza
    command -q eza; and alias ls 'eza --icons --group-directories-first'
    command -q eza; and alias ll 'eza -l --icons --git --group-directories-first'
    command -q eza; and alias la 'eza -la --icons --git --group-directories-first'
    command -q eza; and alias lt 'eza --tree --icons --level=2'
    command -q bat; and alias cat 'bat --paging=never'
    command -q btop; and alias top btop
    command -q dust; and alias du dust

    # cd shortcuts
    alias ..   'cd ..'
    alias ...  'cd ../..'
    alias .... 'cd ../../..'

    # git
    alias g  git
    alias gs 'git status -sb'
    alias ga 'git add'
    alias gc 'git commit'
    alias gp 'git push'
    alias gl 'git log --oneline --graph --decorate'
    alias gd 'git diff'
    alias gco 'git checkout'

    # qol
    alias rg   'rg --hidden --smart-case'
    alias ip   'ip -c'
    alias diff 'diff --color=auto'
    alias jctl 'journalctl -p 3 -xb'
    alias c    clear
    alias h    history
    alias q    exit
    alias ff   fastfetch
    alias y    yazi

    # safety
    alias rm 'rm -i'
    alias cp 'cp -i'
    alias mv 'mv -i'

    # Arch / yay
    alias upd     'yay -Syu'
    alias install 'yay -S'
    alias remove  'yay -Rns'
    alias search  'yay -Ss'
    alias pacs    'pacman -Ss'
    alias pacq    'pacman -Q'
    alias cleanup 'sudo pacman -Rns (pacman -Qtdq)'
    alias fixpac  'sudo rm /var/lib/pacman/db.lck'
    alias mirror  'sudo reflector --country DE --age 24 --protocol https --sort rate --save /etc/pacman.d/mirrorlist'

    # net
    alias ports 'ss -tulpn'
    alias myip  'curl -s https://ifconfig.me; echo'
    alias wifi  nmtui
end
