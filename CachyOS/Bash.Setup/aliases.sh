# =============================================================================
# ARCHIVO DE ALIASES (aliases.sh) - CachyOS (Arch Linux + GNOME)
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
    alias ll='eza -l --icons --git --group-directories-first'       # Listado largo
    alias la='eza -la --icons --git --group-directories-first'      # Listado largo + ocultos
    alias lt='eza -l --sort=modified --icons --git --group-directories-first' # Ordenado por fecha
    alias tree='eza --tree --icons'                                 # Árbol de directorios
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
if command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
    alias less='bat'
fi

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
# 5. GESTIÓN DE PAQUETES (CachyOS / Arch Linux - Pacman & Paru)
# -----------------------------------------------------------------------------
if command -v paru &> /dev/null; then
    alias update='sudo pacman -Sy'
    alias upgrade='paru -Syu'
    alias install='paru -S'
    alias remove='paru -Rns'
    alias search='paru -Ss'
    alias clean='paru -Scc'
    alias list='pacman -Qu'
elif command -v yay &> /dev/null; then
    alias update='sudo pacman -Sy'
    alias upgrade='yay -Syu'
    alias install='yay -S'
    alias remove='yay -Rns'
    alias search='yay -Ss'
    alias clean='yay -Scc'
    alias list='pacman -Qu'
else
    alias update='sudo pacman -Sy'
    alias upgrade='sudo pacman -Syu'
    alias install='sudo pacman -S'
    alias remove='sudo pacman -Rns'
    alias search='pacman -Ss'
    alias clean='sudo pacman -Scc'
    alias list='pacman -Qu'
fi

# -----------------------------------------------------------------------------
# 6. SEGURIDAD Y PRECAUCIÓN
# -----------------------------------------------------------------------------
alias rm='rm -i'                    # Preguntar antes de borrar
alias cp='cp -i'                    # Preguntar antes de sobrescribir al copiar
alias mv='mv -i'                    # Preguntar antes de mover
alias ln='ln -i'                    # Preguntar al crear enlaces si existen
alias mkdir='mkdir -p'              # Crear directorios padre automáticamente
alias chown='chown --preserve-root' # Proteger directorio raíz
alias chmod='chmod --preserve-root' # Proteger directorio raíz
alias chgrp='chgrp --preserve-root' # Proteger directorio raíz

# -----------------------------------------------------------------------------
# 7. UTILIDADES MODERNAS (Rust-based)
# -----------------------------------------------------------------------------
alias h='history'
alias c='clear'
alias sudo='sudo '
alias grep='grep --color=auto'
alias ports='ss -tulanp'                 # Ver puertos abiertos
alias df='duf'                           # Mejorado df
alias du='dust'                          # Mejorado du
alias ps='procs'                         # Mejorado ps
alias top='btm'                          # Mejorado top
alias myip='curl -s ifconfig.me'         # Ver mi IP pública
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
echo "✅ Aliases cargados (CachyOS)"
