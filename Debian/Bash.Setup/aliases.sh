# =============================================================================
# ARCHIVO DE ALIASES (aliases.sh) - Debian Workstation (GNOME Shell Wayland)
# =============================================================================
# Este archivo contiene atajos para hacer la vida en la terminal más rápida y cómoda.
# Compatible con Bash y Zsh.

# Evitar ejecución en subshells y sesiones no interactivas
[[ $- != *i* ]] && return 0 2>/dev/null || true

# -----------------------------------------------------------------------------
# 1. NAVEGACIÓN Y DIRECTORIOS
# -----------------------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias repo='cd ~/Workspace/Repositorios'
alias workspace='cd ~/Workspace'
alias deb='cd ~/Workspace/Repositorios/Linux/Debian'
alias debiantesting='cd ~/Workspace/Repositorios/Linux/DebianTesting'

# -----------------------------------------------------------------------------
# 2. LISTADO DE ARCHIVOS (MODERNO CON FALLBACK)
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
    alias tree='lsd --tree'
else
    alias ls='ls --color=auto --group-directories-first'
    alias ll='ls -lh --color=auto --group-directories-first'
    alias la='ls -lAh --color=auto --group-directories-first'
fi

# -----------------------------------------------------------------------------
# 3. LECTURA DE ARCHIVOS (BAT / BATCAT)
# -----------------------------------------------------------------------------
if command -v batcat &> /dev/null; then
    alias bat='batcat'
    alias cat='batcat --paging=never'
    alias less='batcat'
elif command -v bat &> /dev/null; then
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
# 5. GESTIÓN DE PAQUETES (APT)
# -----------------------------------------------------------------------------
alias update='sudo apt update'
alias upgrade='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias purge='sudo apt purge'
alias search='apt search'
alias clean='sudo apt autoremove -y && sudo apt clean'
alias list-upgradable='apt list --upgradable'
alias pkg-info='apt show'

# -----------------------------------------------------------------------------
# 6. SEGURIDAD Y PRECAUCIÓN EN ARCHIVOS
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
# 7. UTILIDADES MODERNAS (RUST-BASED) CON FALLBACK
# -----------------------------------------------------------------------------
command -v duf &> /dev/null && alias df='duf'
command -v dust &> /dev/null && alias du='dust'
command -v procs &> /dev/null && alias ps='procs'
if command -v btm &> /dev/null; then
    alias top='btm'
elif command -v btop &> /dev/null; then
    alias top='btop'
fi
if command -v fastfetch &> /dev/null; then
    alias ff='fastfetch'
    alias sysinfo='fastfetch'
fi

# -----------------------------------------------------------------------------
# 8. VARIOS Y CONTROL DE RED
# -----------------------------------------------------------------------------
alias h='history'
alias c='clear'
alias sudo='sudo '
alias grep='grep --color=auto'
alias ports='sudo ss -tulanp'
alias myip='curl -s --connect-timeout 2 ifconfig.me'
alias localip='ip -4 addr show | grep -oP "(?<=inet\s)\d+(\.\d+){3}"'

# Cortafuegos Exclusivo (Firewalld - Prohibido UFW)
alias fw='sudo firewall-cmd'
alias fw-status='sudo firewall-cmd --state'
alias fw-active='sudo firewall-cmd --get-active-zones'
alias fw-ports='sudo firewall-cmd --list-ports'
alias fw-services='sudo firewall-cmd --list-services'
alias fw-all='sudo firewall-cmd --list-all'
alias fw-reload='sudo firewall-cmd --reload'

# Recarga dinámica según la shell activa
alias reload='[ -n "$ZSH_VERSION" ] && source ~/.zshrc || source ~/.bashrc'
alias edit-zshrc='${EDITOR:-nano} ~/.zshrc'
alias edit-bashrc='${EDITOR:-nano} ~/.bashrc'
alias edit-shell='[ -n "$ZSH_VERSION" ] && ${EDITOR:-nano} ~/.zshrc || ${EDITOR:-nano} ~/.bashrc'
alias edit-aliases='[ -n "$ZSH_VERSION" ] && (${EDITOR:-nano} ~/.zshrc.d/aliases.sh 2>/dev/null || ${EDITOR:-nano} ~/.zshrc.d/aliases.zsh) || ${EDITOR:-nano} ~/.bashrc.d/aliases.sh'

# Comprobar versión de kernel activo vs última versión en kernel.org
check-kernel-update() {
    local active_kernel
    active_kernel=$(uname -r)
    local latest_kernel
    latest_kernel=$(curl -s --connect-timeout 3 https://www.kernel.org/releases.json 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('latest_link', {}).get('version', 'Desconocido'))" 2>/dev/null || echo "Desconocido")
    echo "================================================================="
    echo "🐧 Kernel activo en el sistema:  $active_kernel"
    echo "📌 Última versión en Kernel.org: v$latest_kernel"
    echo "================================================================="
    if [[ "$active_kernel" != *"$latest_kernel"* ]]; then
        echo "💡 Hay una versión de kernel más reciente disponible en kernel.org."
    else
        echo "✅ Tu kernel coincide con la última versión estable."
    fi
}
alias check-kernel='check-kernel-update'
alias kernel-check='check-kernel-update'
alias cpu-info='lscpu | grep -E "Model name|Architecture|CPU\(s\)"'
alias gpu-info='lspci | grep -iE "vga|3d|display"'
alias ram-info='free -h'
alias disk-info='lsblk -f'

# -----------------------------------------------------------------------------
# 9. VIRTUALIZACIÓN (Libvirt/KVM)
# -----------------------------------------------------------------------------
alias vms='virsh list --all'
alias vmstart='virsh start'
alias vmstop='virsh shutdown'
alias vminfo='virsh dominfo'
alias vmconsole='virsh console'

# -----------------------------------------------------------------------------
# 10. PODMAN (Comandos directos)
# -----------------------------------------------------------------------------
alias p='podman'
alias pc='podman-compose'
alias pps='podman ps'
alias ppsa='podman ps -a'
alias pimg='podman images'
alias pv='podman volume ls'
alias pods='podman pod ps'
alias podsa='podman pod ps -a'
alias pclean='podman system prune -af'

# -----------------------------------------------------------------------------
# 11. IDEs Y HERRAMIENTAS DE DESARROLLO
# -----------------------------------------------------------------------------
alias update-antigravity='sudo "$UPDATE_ANTIGRAVITY_PATH"'
alias update-antigravity-ide='sudo "$UPDATE_ANTIGRAVITY_IDE_PATH"'

# -----------------------------------------------------------------------------
# 12. MENSAJE DE CARGA
# -----------------------------------------------------------------------------
[[ $- == *i* ]] && echo "✅ Aliases cargados (Debian GNOME / Wayland)"
