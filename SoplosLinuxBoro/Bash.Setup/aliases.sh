# =============================================================================
# ARCHIVO DE ALIASES (aliases.sh) - Soplos Linux Boro Workstation (GNOME Shell Wayland)
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
alias soplos='cd ~/Workspace/Repositorios/Linux/SoplosLinuxBoro'
alias soplos-setup='cd ~/Workspace/Repositorios/Linux/SoplosLinuxBoro/Setup'
alias quadlets='cd ~/.config/containers/systemd'

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

# Fallback para fd-find en Debian Testing / Soplos Linux
if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
    alias fd='fdfind'
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
# 5. GESTIÓN DE PAQUETES (APT & FLATPAK - SOPLOS LINUX BORO)
# -----------------------------------------------------------------------------
alias update='sudo apt update'
alias upgrade='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias purge='sudo apt purge'
alias search='apt search'
alias clean='sudo apt autoremove --purge -y && sudo apt clean'
alias list-upgradable='apt list --upgradable'
alias pkg-info='apt show'

# Atajos nativos para Flatpak
if command -v flatpak &>/dev/null; then
    alias fp='flatpak'
    alias fpu='flatpak update'
    alias fpi='flatpak install'
    alias fpls='flatpak list'
    alias fpun='flatpak uninstall'
    alias fp-clean='flatpak uninstall --unused -y'
fi

# Mantenimiento y actualización completa unificada de Soplos Linux Boro
alias soplos-update='sudo apt update && sudo apt upgrade -y && { command -v flatpak &>/dev/null && flatpak update -y || true; }'
alias soplos-clean='sudo apt autoremove --purge -y && sudo apt clean && { command -v flatpak &>/dev/null && flatpak uninstall --unused -y || true; }'

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
# 8. VARIOS, RED Y CORTAFUEGOS (FIREWALLD OBLIGATORIO)
# -----------------------------------------------------------------------------
alias h='history'
alias c='clear'
alias sudo='sudo '
alias grep='grep --color=auto'
alias ports='sudo ss -tulanp'
alias myip='curl -s --connect-timeout 2 ifconfig.me'
alias localip="ip -4 route get 1.1.1.1 2>/dev/null | awk '{print \$7}' || hostname -I | awk '{print \$1}'"

# Cortafuegos UFW (Uncomplicated Firewall - Predeterminado en Soplos Linux Boro)
if command -v ufw &>/dev/null || [ -x /usr/sbin/ufw ] || [ -x /sbin/ufw ]; then
    alias ufw-status='sudo ufw status verbose'
    alias ufw-numbered='sudo ufw status numbered'
    alias ufw-reload='sudo ufw reload'
    alias ufw-enable='sudo ufw enable'
    alias ufw-disable='sudo ufw disable'
    alias ufw-dev-ports='echo "=== 🛡️ Reglas Activas en UFW ===" && sudo ufw status numbered && echo "=== 🔌 Sockets Escuchando Localmente ===" && sudo ss -tulpn | grep -E "3000|5173|8000|8080|9090|1714|1764|8443"'

    # Atajos genéricos 'fw' apuntando a UFW
    alias fw='sudo ufw'
    alias fw-status='sudo ufw status verbose'
    alias fw-reload='sudo ufw reload'
    alias fw-all='sudo ufw status numbered'

    # Gestión ágil de puertos con UFW (Vite, Next.js, FastAPI, Cockpit, GSConnect)
    fw-open() {
        if [ -z "${1:-}" ]; then
            echo "Uso: fw-open <puerto>[/protocolo] (por defecto tcp)"
            echo "Ejemplo: fw-open 5173 (Vite) | fw-open 3000 (Next.js) | fw-open 8000 (FastAPI)"
            return 1
        fi
        local port="$1"
        [[ "$port" != */* ]] && port="$port/tcp"
        sudo ufw allow "$port"
        echo "✅ Puerto $port permitido en UFW."
    }

    fw-close() {
        if [ -z "${1:-}" ]; then
            echo "Uso: fw-close <puerto>[/protocolo] (por defecto tcp)"
            return 1
        fi
        local port="$1"
        [[ "$port" != */* ]] && port="$port/tcp"
        sudo ufw delete allow "$port"
        echo "🔒 Puerto $port revocado en UFW."
    }

    alias ufw-open='fw-open'
    alias ufw-close='fw-close'

# Fallback si el sistema utiliza Firewalld
elif command -v firewall-cmd &>/dev/null; then
    alias fw='sudo firewall-cmd'
    alias fw-status='sudo firewall-cmd --state'
    alias fw-active='sudo firewall-cmd --get-active-zones'
    alias fw-ports='sudo firewall-cmd --list-ports'
    alias fw-services='sudo firewall-cmd --list-services'
    alias fw-all='sudo firewall-cmd --list-all'
    alias fw-reload='sudo firewall-cmd --reload'

    fw-open() {
        if [ -z "${1:-}" ]; then
            echo "Uso: fw-open <puerto>[/protocolo] (por defecto tcp)"
            return 1
        fi
        local port="$1"
        [[ "$port" != */* ]] && port="$port/tcp"
        sudo firewall-cmd --add-port="$port" --permanent && sudo firewall-cmd --reload
        echo "✅ Puerto $port abierto en Firewalld (permanente)."
    }

    fw-close() {
        if [ -z "${1:-}" ]; then
            echo "Uso: fw-close <puerto>[/protocolo] (por defecto tcp)"
            return 1
        fi
        local port="$1"
        [[ "$port" != */* ]] && port="$port/tcp"
        sudo firewall-cmd --remove-port="$port" --permanent && sudo firewall-cmd --reload
        echo "🔒 Puerto $port cerrado en Firewalld."
    }
fi

# Audio PipeWire / WirePlumber (Nativo Wayland - wpctl)
if command -v wpctl &>/dev/null; then
    alias vol='wpctl get-volume @DEFAULT_AUDIO_SINK@'
    alias vol-up='wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+'
    alias vol-down='wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-'
    alias vol-mute='wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle'
    alias mic-mute='wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle'
    alias audio-status='wpctl status'
fi

# Portapapeles Wayland nativo (wl-clipboard)
if command -v wl-copy &>/dev/null; then
    alias clip='wl-copy'
    alias paste='wl-paste'
fi

# Recarga dinámica según la shell activa
alias reload='[ -n "$ZSH_VERSION" ] && source ~/.zshrc || source ~/.bashrc'
alias edit-zshrc='${EDITOR:-nano} ~/.zshrc'
alias edit-bashrc='${EDITOR:-nano} ~/.bashrc'
alias edit-shell='[ -n "$ZSH_VERSION" ] && ${EDITOR:-nano} ~/.zshrc || ${EDITOR:-nano} ~/.bashrc'
alias edit-aliases='[ -n "$ZSH_VERSION" ] && (${EDITOR:-nano} ~/.zshrc.d/aliases.sh 2>/dev/null || ${EDITOR:-nano} ~/.zshrc.d/aliases.zsh) || ${EDITOR:-nano} ~/.bashrc.d/aliases.sh'

# -----------------------------------------------------------------------------
# 9. HARDWARE AMD, TELEMETRÍA Y SISTEMA
# -----------------------------------------------------------------------------
alias cpu-info='lscpu | grep -E "Model name|Architecture|CPU\(s\)|Thread|MHz"'
alias gpu-info='lspci -nnk | grep -iA3 -E "vga|3d|display"'
alias amd-gpu='lspci -nnk | grep -iA3 -E "vga|3d|display"'
alias ram-info='free -h'
alias zram-info='command -v zramctl &>/dev/null && zramctl || free -h'
alias disk-info='lsblk -f'
alias temp-info='command -v sensors &>/dev/null && sensors || echo "Instala lm-sensors para ver temperaturas de los sensores AMD."'

# Comprobar actualizaciones de kernel (APT y Kernel.org)
check-kernel-update() {
    local active_kernel
    active_kernel=$(uname -r)
    echo "================================================================="
    echo "🐧 Kernel activo en el sistema:  $active_kernel"
    echo "📦 Paquetes de kernel en APT:"
    dpkg -l | grep -E "linux-image-[0-9]" | awk '{print "   • " $2 " (" $3 ")"}'
    echo "-----------------------------------------------------------------"
    local latest_kernel
    latest_kernel=$(curl -s --connect-timeout 2 https://www.kernel.org/releases.json 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('latest_link', {}).get('version', 'Desconocido'))" 2>/dev/null || echo "Desconocido")
    echo "📌 Última versión en Kernel.org: v$latest_kernel"
    echo "================================================================="
}
alias check-kernel='check-kernel-update'
alias kernel-check='check-kernel-update'

# -----------------------------------------------------------------------------
# 10. ORQUESTACIÓN CON JUSTFILE (just)
# -----------------------------------------------------------------------------
if command -v just &>/dev/null; then
    alias j='just'
    alias js='just status'
    alias jb='just build'
    alias ju='just update'
fi

# -----------------------------------------------------------------------------
# 11. VIRTUALIZACIÓN (Libvirt/KVM)
# -----------------------------------------------------------------------------
alias vms='virsh list --all'
alias vmstart='virsh start'
alias vmstop='virsh shutdown'
alias vminfo='virsh dominfo'
alias vmconsole='virsh console'

# -----------------------------------------------------------------------------
# 12. PODMAN (Comandos directos)
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
# 13. IDEs Y HERRAMIENTAS DE DESARROLLO
# -----------------------------------------------------------------------------
alias update-antigravity='sudo "$UPDATE_ANTIGRAVITY_PATH"'
alias update-antigravity-ide='sudo "$UPDATE_ANTIGRAVITY_IDE_PATH"'

# -----------------------------------------------------------------------------
# 14. MENSAJE DE CARGA
# -----------------------------------------------------------------------------
[[ $- == *i* ]] && echo "✅ Aliases cargados (Soplos Linux Boro GNOME / Wayland)"
