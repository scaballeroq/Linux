# =============================================================================
# ARCHIVO DE ALIASES (aliases.sh)
# =============================================================================
# Este archivo contiene atajos (aliases) para comandos utilizados frecuentemente.
# Su objetivo es ahorrar pulsaciones de teclado y mejorar la seguridad añadiendo
# opciones por defecto a comandos peligrosos.

# -----------------------------------------------------------------------------
# 1. NAVEGACIÓN
# -----------------------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias repo='cd ~/Workspace/Repositorios'

# -----------------------------------------------------------------------------
# 2. LISTADO DE ARCHIVOS (ls / eza / lsd)
# -----------------------------------------------------------------------------
if command -v eza &> /dev/null; then
    alias ls='eza --icons --git --group-directories-first'
    alias ll='eza -l --icons --git --group-directories-first'
    alias la='eza -la --icons --git --group-directories-first'
    alias lt='eza -l --sort=modified --icons --git --group-directories-first'
    alias tree='eza --tree --icons'
elif command -v lsd &> /dev/null; then
    alias ls='lsd --group-directories-first'
    alias ll='lsd -l --group-directories-first'
    alias la='lsd -la --group-directories-first'
else
    alias ls='ls --color=auto --group-directories-first'
    alias ll='ls -lah'
    alias la='ls -A'
    alias l='ls -CF'
    alias lt='ls -lhtr'
fi

# -----------------------------------------------------------------------------
# 3. LECTURA DE ARCHIVOS (cat / bat)
# -----------------------------------------------------------------------------
alias cat='bat --paging=never'
alias less='bat'

# -----------------------------------------------------------------------------
# 4. GIT (Control de versiones)
# -----------------------------------------------------------------------------
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gca='git commit -a'
alias gcm='git commit -m'
alias gp='git pull'
alias gph='git push'
alias gF='git fetch'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gbr='git branch -r'
alias gba='git branch -a'

# -----------------------------------------------------------------------------
# 5. GESTIÓN DE PAQUETES (PACMAN + YAY)
# -----------------------------------------------------------------------------
alias update='sudo pacman -Sy'
alias upgrade='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias search='pacman -Ss'
alias clean='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null; sudo pacman -Sc --noconfirm'
alias list='pacman -Qu'
alias aur-install='yay -S'
alias aur-remove='yay -Rns'
alias aur-search='yay -Ss'
alias aur-upgrade='yay -Syu'

# -----------------------------------------------------------------------------
# 6. SEGURIDAD Y PRECAUCIÓN
# -----------------------------------------------------------------------------
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'
alias mkdir='mkdir -p'
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# -----------------------------------------------------------------------------
# 7. UTILIDADES MODERNAS (Rust-based)
# -----------------------------------------------------------------------------
alias h='history'
alias c='clear'
alias sudo='sudo '
alias grep='grep --color=auto'
alias ports='ss -tulanp'
alias df='duf'
alias du='dust'
alias ps='procs'
alias top='btm'
alias myip='curl -s ifconfig.me'
alias localip='ip -4 addr show | grep -oP "(?<=inet\s)\d+(\.\d+){3}"'
alias ff='fastfetch'
alias reload='source ~/.bashrc'

# -----------------------------------------------------------------------------
# 8. VIRTUALIZACIÓN (Libvirt/KVM)
# -----------------------------------------------------------------------------
alias vms='virsh list --all'
alias vmstart='virsh start'
alias vmstop='virsh shutdown'
alias vminfo='virsh dominfo'

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Aliases"
