# =============================================================================
# ARCHIVO DE ALIASES (aliases.sh) - Adaptado para CachyOS (KDE Plasma 6)
# =============================================================================
# Este archivo contiene atajos (aliases) para comandos utilizados frecuentemente.
# Optimizado para CachyOS (Arch Linux, x86-64-v3/v4) con KDE Plasma 6, Wayland y herramientas Rust.

# 1. NAVEGACIÓN RÁPIDA
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias repo='cd ~/Workspace/Repositorios'
alias repos='cd ~/Workspace/Repositorios'
alias cachyos='cd ~/Workspace/Repositorios/Linux/CachyOS'

# 2. INTEGRACIÓN CON KDE PLASMA Y ESCRITORIO
alias open='xdg-open'
alias o='xdg-open'
alias dolphin='dolphin . &>/dev/null &'
alias trash='gio trash'

# Portapapeles (Wayland nativo con fallback a X11)
if command -v wl-copy &> /dev/null; then
    alias clipcopy='wl-copy'
    alias clippaste='wl-paste'
elif command -v xclip &> /dev/null; then
    alias clipcopy='xclip -selection clipboard'
    alias clippaste='xclip -selection clipboard -o'
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

# 5. GESTIÓN DE PAQUETES (PACMAN / PARU)
alias update='sudo pacman -Syu'
alias upgrade='sudo pacman -Syu --noconfirm'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias search='pacman -Ss'
alias clean='sudo pacman -Sc --noconfirm && sudo pacman -Scc --noconfirm'
alias list='pacman -Qe'
alias pkg-info='pacman -Si'
alias pkg-history='cat /var/log/pacman.log | grep "installed\|removed" | tail -20'
alias orphan='pacman -Qdt'
alias clean-orphans='sudo pacman -Rns $(pacman -Qdtq) --noconfirm 2>/dev/null || true'

# AUR helpers
if command -v paru &> /dev/null; then
    alias aur='paru'
    alias aur-update='paru -Syu'
    alias aur-search='paru -Ss'
elif command -v yay &> /dev/null; then
    alias aur='yay'
    alias aur-update='yay -Syu'
    alias aur-search='yay -Ss'
fi

# Clasificar espejo más rápido para la red actual
alias rate-mirrors='cachyos-rate-mirrors'

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

# 7. VARIOS Y CONTROL DE KERNEL
alias h='history'
alias c='clear'
alias sudo='sudo '
alias grep='grep --color=auto'
alias ports='sudo ss -tulanp'
alias myip='curl -s --connect-timeout 2 ifconfig.me'
alias localip='ip -4 addr show | grep -oP "(?<=inet\s)\d+(\.\d+){3}"'

# Recarga dinámica según la shell activa
alias reload='[ -n "$ZSH_VERSION" ] && source ~/.zshrc || source ~/.bashrc'
alias edit-zshrc='${EDITOR:-nano} ~/.zshrc'
alias edit-bashrc='${EDITOR:-nano} ~/.bashrc'
alias edit-shell='[ -n "$ZSH_VERSION" ] && ${EDITOR:-nano} ~/.zshrc || ${EDITOR:-nano} ~/.bashrc'
alias edit-aliases='[ -n "$ZSH_VERSION" ] && (${EDITOR:-nano} ~/.zshrc.d/aliases.sh 2>/dev/null || ${EDITOR:-nano} ~/.zshrc.d/aliases.zsh) || ${EDITOR:-nano} ~/.bashrc.d/aliases.sh'
alias ff='fastfetch'
alias sysinfo='ff'

# Comprobar versión de kernel activo vs última versión en kernel.org
check-kernel-update() {
    local active_kernel
    active_kernel=$(uname -r)
    local latest_kernel="Desconocido"

    local raw_json
    raw_json=$(curl -s --connect-timeout 3 -m 6 https://www.kernel.org/releases.json 2>/dev/null || true)

    if [ -n "$raw_json" ]; then
        if command -v jq &>/dev/null; then
            latest_kernel=$(echo "$raw_json" | jq -r '.latest_link.version // "Desconocido"' 2>/dev/null || echo "Desconocido")
        elif command -v python3 &>/dev/null; then
            latest_kernel=$(echo "$raw_json" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('latest_link', {}).get('version', 'Desconocido'))" 2>/dev/null || echo "Desconocido")
        fi
    fi

    echo "================================================================="
    echo "🐧 Kernel activo en el sistema:  $active_kernel"
    echo "📌 Última versión en Kernel.org: v$latest_kernel"
    echo "================================================================="
    if [ "$latest_kernel" != "Desconocido" ] && [[ "$active_kernel" != *"$latest_kernel"* ]]; then
        echo "💡 Hay una versión más reciente disponible en el sistema/repositorios:"
        echo "   sudo pacman -Syu"
    else
        echo "✅ Tu kernel está actualizado a la última versión estable."
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

echo "✅ Aliases modernizados cargados (Pacman/Paru, KDE Plasma, Kernel-Check, Rust tools)"

