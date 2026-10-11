# =============================================================================
# VARIABLES DE ENTORNO (environment.sh) - Adaptado para Manjaro Linux (Bash)
# =============================================================================

export EDITOR='nano'
export VISUAL='nano'

export LESS='-R'
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'
export MANPAGER="less -R --use-color -Dd+r -Du+b"

if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/bin" ]; then
    export PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/go/bin" ]; then
    export PATH="$HOME/go/bin:$PATH"
fi

if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

if command -v mise &> /dev/null; then
    eval "$(mise activate bash)"
fi

export GPG_TTY=$(tty 2>/dev/null || echo "")

export UPDATE_ANTIGRAVITY_PATH="/usr/local/bin/update-antigravity"
export UPDATE_ANTIGRAVITY_IDE_PATH="/usr/local/bin/update-antigravity-ide"

echo "✅ Variables de entorno para Bash aplicadas (PATH, EDITOR, LESS, Mise...)"
