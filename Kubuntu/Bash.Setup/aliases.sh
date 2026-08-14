# =============================================================================
# ARCHIVO DE ALIASES (aliases.sh) - Adaptado para Kubuntu
# =============================================================================
# Este archivo contiene atajos (aliases) para comandos utilizados frecuentemente.
# Su objetivo es ahorrar pulsaciones de teclado y mejorar la seguridad añadiendo
# opciones por defecto a comandos peligrosos.

# -----------------------------------------------------------------------------
# 1. NAVEGACIÓN
# -----------------------------------------------------------------------------
# Atajos rápidos para moverse por el sistema de archivos.

# Subir un nivel de directorio (equivalente a "cd ..")
alias ..='cd ..'
# Subir dos niveles de directorio
alias ...='cd ../..'
# Subir tres niveles de directorio
alias ....='cd ../../..'
# Ir rápidamente al directorio "home"
alias ~='cd ~'
# Ir a la carpeta de Repositorios
alias repo='cd ~/Workspace/Repositorios'

# -----------------------------------------------------------------------------
# 2. LISTADO DE ARCHIVOS (ls / eza / lsd)
# -----------------------------------------------------------------------------
# Mejora el comando 'ls' básico. Intenta usar herramientas modernas como 'eza'
# o 'lsd' si están instaladas para mostrar iconos, colores y metadatos git.
# Si no, recurre a un 'ls' mejorado con colores.

if command -v eza &> /dev/null; then
    # 'eza' es un reemplazo moderno de ls.
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
alias cat='bat --paging=never' # Imprimir sin paginación
alias less='bat'               # Usar bat como paginador

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
# 5. GESTIÓN DE PAQUETES (APT)
# -----------------------------------------------------------------------------
alias update='sudo apt update'
alias upgrade='sudo apt upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'
alias clean='sudo apt autoremove -y && sudo apt clean'
alias list='apt list --upgradable'

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
alias ports='ss -tulanp'                 # Ver puertos abiertos (moderno)
alias df='duf'                           # Mejorado df
alias du='dust'                          # Mejorado du
alias ps='procs'                         # Mejorado ps
alias top='btm'                          # Mejorado top
alias myip='curl -s ifconfig.me'         # Ver mi IP pública
alias localip='ip -4 addr show | grep -oP "(?<=inet\s)\d+(\.\d+){3}"'
alias ff='fastfetch'
alias reload='source ~/.bashrc'
alias edit-bashrc='${EDITOR:-nano} ~/.bashrc'
alias edit-aliases='${EDITOR:-nano} ~/.bashrc.d/aliases.sh'
alias sysinfo='ff'

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
echo "✅ Aliases cargados"
