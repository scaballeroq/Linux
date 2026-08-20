# =============================================================================
# ARCHIVO DE ALIASES (aliases.zsh) - Adaptado para Manjaro Linux (ZSH)
# =============================================================================
# Este archivo contiene atajos (aliases) para comandos utilizados frecuentemente.

# 1. NAVEGACIÓN RÁPIDA
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias repos='cd ~/Workspace/Repositorios'
alias manjaro='cd ~/Workspace/Repositorios/Linux/Manjaro'
alias arch='cd ~/Workspace/Repositorios/Linux/ArchLinux'
alias cachyos='cd ~/Workspace/Repositorios/Linux/CachyOS'
alias debiantesting='cd ~/Workspace/Repositorios/Linux/DebianTesting'

# 2. MEJORAS DE 'LS' (USANDO EZA)
if command -v eza &> /dev/null; then
    alias ll='eza -l --icons --git --group-directories-first'
    alias la='eza -la --icons --git --group-directories-first'
    alias lt='eza -l --sort=modified --icons --git --group-directories-first'
    alias tree='eza --tree --icons'
else
    alias ll='ls -lh --color=auto --group-directories-first'
    alias la='ls -lAh --color=auto --group-directories-first'
fi

# 3. SEGURIDAD Y PREVENCIÓN DE ERRORES
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# 4. GESTIÓN DE PAQUETES (PACMAN Y PAMAC)
alias update='sudo pacman -Syu'
alias upgrade='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias search='pacman -Ss'
alias clean='sudo pacman -Sc --noconfirm'
alias orphans='pacman -Qtdq | sudo pacman -Rns - 2>/dev/null || echo "No hay paquetes huérfanos."'
alias pkg-list='pacman -Qe'

# Pamac (Gestor gráfico/CLI con soporte AUR)
if command -v pamac &> /dev/null; then
    alias p-update='pamac update --aur'
    alias p-install='pamac install'
    alias p-remove='pamac remove'
    alias p-search='pamac search'
    alias p-clean='pamac clean --build-files'
fi

# 5. UTILIDADES MODERNAS (RUST-BASED)
command -v bat &> /dev/null && alias cat='bat --paging=never'
command -v bat &> /dev/null && alias less='bat'
command -v duf &> /dev/null && alias df='duf'
command -v dust &> /dev/null && alias du='dust'
command -v du-dust &> /dev/null && alias du='du-dust'
command -v procs &> /dev/null && alias ps='procs'
command -v btm &> /dev/null && alias top='btm'

# 6. VARIOS Y CONTROL DE KERNEL
alias ports='sudo ss -tulanp'
alias myip='curl -s ifconfig.me'
alias reload='source ~/.zshrc'
alias edit-zshrc='${EDITOR:-nano} ~/.zshrc'
alias edit-aliases='${EDITOR:-nano} ~/.zshrc.d/aliases.zsh'
alias c='clear'
alias ff='fastfetch'
alias sysinfo='ff'

# Comprobar versión de kernel activo vs última versión en kernel.org
check-kernel-update() {
    local active_kernel
    active_kernel=$(uname -r)
    local latest_kernel
    latest_kernel=$(curl -s https://www.kernel.org/releases.json 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('latest_link', {}).get('version', 'Desconocido'))" 2>/dev/null || echo "Desconocido")
    echo "================================================================="
    echo "🐧 Kernel activo en Manjaro:      $active_kernel"
    echo "📌 Última versión en Kernel.org: v$latest_kernel"
    echo "================================================================="
    if [[ "$active_kernel" != *"$latest_kernel"* ]]; then
        echo "💡 Hay una versión más reciente disponible. Para compilar ejecuta:"
        echo "   just build-kernel"
    else
        echo "✅ Tu kernel está actualizado a la última versión estable."
    fi
}
alias check-kernel='check-kernel-update'

# 7. VIRTUALIZACIÓN (Libvirt/KVM)
alias vms='virsh list --all'
alias vmstart='virsh start'
alias vmstop='virsh shutdown'
alias vminfo='virsh dominfo'

# 8. IDEs
alias update-antigravity='sudo "$UPDATE_ANTIGRAVITY_PATH"'
alias update-antigravity-ide='sudo "$UPDATE_ANTIGRAVITY_IDE_PATH"'

echo "✅ Aliases modernizados de Manjaro Linux (ZSH) cargados"
