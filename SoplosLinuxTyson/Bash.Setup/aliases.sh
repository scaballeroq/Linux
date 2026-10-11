# =============================================================================
# ARCHIVO DE ALIASES (aliases.sh) - Soplos Linux Tyson
# =============================================================================
# Este archivo contiene atajos (aliases) para comandos utilizados frecuentemente.

# -----------------------------------------------------------------------------
# 1. NAVEGACIÓN RÁPIDA
# -----------------------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias repos='cd ~/Workspace/Repositorios'
alias soplos='cd ~/Workspace/Repositorios/Linux/SoplosLinuxTyson'
alias tyson='cd ~/Workspace/Repositorios/Linux/SoplosLinuxTyson'
alias kdebian='cd ~/Workspace/Repositorios/Linux/SoplosLinuxTyson'

# -----------------------------------------------------------------------------
# 2. MEJORAS DE 'LS' (USANDO EZA) Y UTILIDADES CLI
# -----------------------------------------------------------------------------
if command -v eza &> /dev/null; then
    alias ll='eza -l --icons --git --group-directories-first'
    alias la='eza -la --icons --git --group-directories-first'
    alias lt='eza -l --sort=modified --icons --git --group-directories-first'
    alias tree='eza --tree --icons'
else
    alias ll='ls -lh --color=auto --group-directories-first'
    alias la='ls -lAh --color=auto --group-directories-first'
fi

# Utilidades modernas (Rust / Alternativas CLI)
if command -v batcat &> /dev/null; then
    alias bat='batcat'
    alias cat='batcat --paging=never'
elif command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
fi

command -v fdfind &> /dev/null && alias fd='fdfind'
command -v duf &> /dev/null && alias df='duf'
command -v du-dust &> /dev/null && alias du='du-dust'
command -v dust &> /dev/null && alias du='dust'
command -v procs &> /dev/null && alias ps='procs'
command -v btm &> /dev/null && alias top='btm'

# -----------------------------------------------------------------------------
# 3. SEGURIDAD Y PREVENCIÓN DE ERRORES
# -----------------------------------------------------------------------------
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# -----------------------------------------------------------------------------
# 4. GESTIÓN DE PAQUETES (APT)
# -----------------------------------------------------------------------------
alias update='sudo apt update'
alias upgrade='sudo apt upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'
alias clean='sudo apt autoremove -y && sudo apt clean'
alias list='apt list --upgradable'

# -----------------------------------------------------------------------------
# 5. ADMINISTRACIÓN DEL SISTEMA (SYSTEMD & DRACUT)
# -----------------------------------------------------------------------------
alias sc='sudo systemctl'
alias scu='systemctl --user'
alias jc='sudo journalctl -xe'
alias jcu='journalctl --user -xe'
alias dracut-rebuild='sudo dracut -f --kver $(uname -r)'
alias grub-update='sudo update-grub'

# -----------------------------------------------------------------------------
# 6. RED Y CONTROL DE KERNEL
# -----------------------------------------------------------------------------
alias ports='sudo ss -tulanp'
alias myip='curl -s ifconfig.me'
alias reload='source ~/.bashrc'
alias edit-bashrc='${EDITOR:-nano} ~/.bashrc'
alias edit-aliases='${EDITOR:-nano} ~/.bashrc.d/aliases.sh'
alias c='clear'
alias ff='fastfetch'
alias sysinfo='fastfetch'

# Comprobar versión de kernel activo vs última versión en kernel.org
check-kernel-update() {
    local active_kernel
    active_kernel=$(uname -r)
    local json_data
    json_data=$(curl -s --connect-timeout 5 https://www.kernel.org/releases.json 2>/dev/null)

    if [ -z "$json_data" ]; then
        echo "================================================================="
        echo "🐧 Kernel activo en el sistema:  $active_kernel"
        echo "⚠️  No se pudo consultar kernel.org (sin conexión o error en API)."
        echo "================================================================="
        return 1
    fi

    local latest_kernel
    latest_kernel=$(echo "$json_data" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('latest_link', {}).get('version', ''))" 2>/dev/null || echo "")

    if [ -z "$latest_kernel" ]; then
        echo "================================================================="
        echo "🐧 Kernel activo en el sistema:  $active_kernel"
        echo "⚠️  Respuesta no válida al consultar la versión de kernel.org."
        echo "================================================================="
        return 1
    fi

    echo "================================================================="
    echo "🐧 Kernel activo en el sistema:  $active_kernel"
    echo "📌 Última versión en Kernel.org: v$latest_kernel"
    echo "================================================================="
    if [[ "$active_kernel" != *"$latest_kernel"* ]]; then
        echo "💡 Hay una versión más reciente disponible (v$latest_kernel)."
        echo "   Para compilar y actualizar ejecuta: just build-kernel"
    else
        echo "✅ Tu kernel está actualizado a la última versión estable."
    fi
}
alias check-kernel='check-kernel-update'

# -----------------------------------------------------------------------------
# 7. VIRTUALIZACIÓN (Libvirt/KVM)
# -----------------------------------------------------------------------------
alias vms='virsh list --all'
alias vmstart='virsh start'
alias vmstop='virsh shutdown'
alias vminfo='virsh dominfo'

# -----------------------------------------------------------------------------
# 8. IDEs Y HERRAMIENTAS
# -----------------------------------------------------------------------------
alias update-antigravity='sudo "${UPDATE_ANTIGRAVITY_PATH:-/usr/local/bin/update-antigravity}"'
alias update-antigravity-ide='sudo "${UPDATE_ANTIGRAVITY_IDE_PATH:-/usr/local/bin/update-antigravity-ide}"'

# =============================================================================
# MENSAJE DE CARGA (Solo en sesiones interactivas)
# =============================================================================
[[ $- == *i* ]] && [ -t 1 ] && echo "✅ Aliases modernizados cargados (APT, Systemd, Dracut, Kernel-Check, Rust tools, Git, Seguridad)" || true
