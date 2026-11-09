# =============================================================================
# ARCHIVO DE ALIASES (aliases.sh) - Adaptado para CachyOS Workstation (GNOME)
# =============================================================================
# Este archivo contiene atajos (aliases) para comandos utilizados frecuentemente.
# Optimizado para CachyOS Workstation con GNOME, Wayland y herramientas Rust.

# Evitar ejecución en subshells y sesiones no interactivas (ej: scp, rsync)
[[ $- != *i* ]] && return 0 2>/dev/null || true

# 1. NAVEGACIÓN RÁPIDA
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias repo='cd ~/Proyectos'
alias repos='cd ~/Proyectos'
alias cachyos='cd ~/Proyectos/Linux/CachyOS-Gnome'
alias fedora='cd ~/Proyectos/Linux/Fedora-Workstation'

# 2. INTEGRACIÓN CON GNOME Y ESCRITORIO
alias open='xdg-open'
alias o='xdg-open'
alias nautilus='nautilus . &>/dev/null &'
alias files='nautilus . &>/dev/null &'
alias trash='gio trash'

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

# 4. GIT
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -m'
alias gca='git commit -am'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias glog='git log --oneline --graph --decorate'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gba='git branch -a'

# 5. GESTIÓN DE PAQUETES (PACMAN / PARU)
if command -v paru &>/dev/null; then
    alias update='paru -Sy'
    alias upgrade='paru -Syu'
    alias install='paru -S --needed'
    alias remove='sudo pacman -Rns'
    alias search='paru -Ss'
    alias clean='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null || true && sudo paccache -r 2>/dev/null || sudo pacman -Sc --noconfirm'
    alias list='pacman -Qu'
    alias installed='pacman -Qe'
    alias pkg-info='pacman -Qi'
    alias pkg-files='pacman -Ql'
    alias pacup='paru -Syu --noconfirm'
    alias pacin='paru -S --needed'
    alias pacrem='sudo pacman -Rns'
else
    alias update='sudo pacman -Sy'
    alias upgrade='sudo pacman -Syu'
    alias install='sudo pacman -S --needed'
    alias remove='sudo pacman -Rns'
    alias search='pacman -Ss'
    alias clean='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null || true && sudo pacman -Sc --noconfirm'
    alias list='pacman -Qu'
    alias installed='pacman -Qe'
    alias pkg-info='pacman -Qi'
    alias pkg-files='pacman -Ql'
    alias pacup='sudo pacman -Syu --noconfirm'
    alias pacin='sudo pacman -S --needed'
    alias pacrem='sudo pacman -Rns'
fi
alias mirrors='sudo cachyos-rate-mirrors'

# 6. SEGURIDAD Y PREVENCIÓN DE ERRORES
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'
alias mkdir='mkdir -p'
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# 7. UTILIDADES MODERNAS (RUST-BASED) CON FALLBACK
if command -v batcat &> /dev/null; then
    alias bat='batcat'
    alias cat='batcat --paging=never'
    alias less='batcat'
elif command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
    alias less='bat'
fi

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

# 8. VARIOS Y CONTROL DE RED
alias h='history'
alias c='clear'
alias sudo='sudo '
alias grep='grep --color=auto'
alias ports='sudo ss -tulanp'
alias myip='curl -s --connect-timeout 2 ifconfig.me'
alias localip='ip -4 addr show | grep -oP "(?<=inet\s)\d+(\.\d+){3}"'

# Cortafuegos Exclusivo (Firewalld)
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

# 9. VIRTUALIZACIÓN (Libvirt/KVM)
alias vms='virsh list --all'
alias vmstart='virsh start'
alias vmstop='virsh shutdown'
alias vminfo='virsh dominfo'

# 10. IDEs
alias update-antigravity='sudo /usr/local/bin/update-antigravity'
alias update-antigravity-ide='sudo /usr/local/bin/update-antigravity-ide'

echo "✅ Aliases modernizados cargados (Pacman/Paru, GNOME, Firewalld, Git, Rust tools)"
