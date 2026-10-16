# =============================================================================
# ARCHIVO DE ALIASES (aliases.sh) - Adaptado para OpenSUSE Tumbleweed (KDE Plasma)
# =============================================================================
# Este archivo contiene atajos (aliases) para comandos utilizados frecuentemente.
# Optimizado para OpenSUSE Tumbleweed con KDE Plasma 6, Wayland y utilidades Rust.

# Evitar ejecución en subshells y sesiones no interactivas (ej: scp, rsync)
[[ $- != *i* ]] && return 0 2>/dev/null || true

# 1. NAVEGACIÓN RÁPIDA
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias repo='cd ~/Workspace/Repositorios'
alias repos='cd ~/Workspace/Repositorios'
alias opensuse='cd ~/Workspace/Repositorios/Linux/OpenSuseTumbleweed'
alias tumbleweed='cd ~/Workspace/Repositorios/Linux/OpenSuseTumbleweed'
alias linux='cd ~/Workspace/Repositorios/Linux'

# 2. INTEGRACIÓN CON KDE PLASMA Y ESCRITORIO
alias open='xdg-open'
alias o='xdg-open'
alias dolphin='dolphin . &>/dev/null &'
alias files='dolphin . &>/dev/null &'
alias trash='kioclient6 move "$@" trash:/ 2>/dev/null || kioclient5 move "$@" trash:/ 2>/dev/null || gio trash "$@" 2>/dev/null || rm -i'

# Portapapeles (Wayland nativo con wl-clipboard)
if command -v wl-copy &> /dev/null; then
    alias clipcopy='wl-copy'
    alias clippaste='wl-paste'
fi

# 3. MEJORAS DE 'LS' (USANDO EZA)
if command -v eza &> /dev/null; then
    alias ls='eza --icons --git --group-directories-first'
    alias ll='eza -l --icons --git --group-directories-first'
    alias la='eza -la --icons --git --group-directories-first'
    alias lt='eza -l --sort=modified --icons --git --group-directories-first'
    alias tree='eza --tree --icons'
else
    alias ls='ls --color=auto --group-directories-first'
    alias ll='ls -lh --color=auto --group-directories-first'
    alias la='ls -lAh --color=auto --group-directories-first'
fi

# 4. SEGURIDAD Y PREVENCIÓN DE ERRORES
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'
alias mkdir='mkdir -p'
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# 5. GESTIÓN DE PAQUETES (ZYPPER / SNAPPER)
alias dup='sudo zypper dup'
alias update='sudo zypper refresh && sudo zypper dup'
alias upgrade='sudo zypper refresh && sudo zypper dup'
alias install='sudo zypper install'
alias remove='sudo zypper remove -u'
alias search='zypper search'
alias clean='sudo zypper clean --all'
alias list='zypper list-updates'
alias installed='zypper search -i'
alias pkg-info='zypper info'
alias snapshots='snapper list'
alias snap-status='sudo snapper status'
alias snap-diff='sudo snapper diff'
alias snap-create='sudo snapper create --description'
alias snap-rollback='sudo snapper rollback'

# 6. UTILIDADES MODERNAS (RUST-BASED)
if command -v batcat &> /dev/null; then
    alias bat='batcat'
    alias cat='batcat --paging=never'
    alias less='batcat'
elif command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
    alias less='bat'
fi

# Reemplazos si las herramientas están instaladas
command -v duf &> /dev/null && alias df='duf'
command -v dust &> /dev/null && alias du='dust'
command -v procs &> /dev/null && alias ps='procs'
command -v btm &> /dev/null && alias top='btm'

# 7. VARIOS Y CONTROL DE RED
alias h='history'
alias c='clear'
alias sudo='sudo '
alias grep='grep --color=auto'
alias ports='sudo ss -tulanp'
alias myip='curl -s --connect-timeout 2 ifconfig.me'
alias localip='ip -4 addr show | grep -oP "(?<=inet\s)\d+(\.\d+){3}"'

# Cortafuegos (Firewalld)
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
alias ff='fastfetch'
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

# 8. VIRTUALIZACIÓN (Libvirt/KVM)
alias vms='virsh list --all'
alias vmstart='virsh start'
alias vmstop='virsh shutdown'
alias vminfo='virsh dominfo'

# 9. IDEs
alias update-antigravity='sudo "$UPDATE_ANTIGRAVITY_PATH"'
alias update-antigravity-ide='sudo "$UPDATE_ANTIGRAVITY_IDE_PATH"'

# 10. MENSAJE DE CARGA
echo "✅ Aliases cargados"
