# =============================================================================
# ARCHIVO DE ALIASES (aliases.sh) - Omarchy
# =============================================================================
# Este archivo contiene atajos (aliases) para comandos utilizados frecuentemente.

# -----------------------------------------------------------------------------
# 1. NAVEGACIÓN
# -----------------------------------------------------------------------------
alias ~='cd ~'
alias repos='cd ~/Workspace/Repositorios'
alias omarchy='cd ~/Workspace/Repositorios/Linux/Omarchy'
alias arch='cd ~/Workspace/Repositorios/Linux/Arch'

# -----------------------------------------------------------------------------
# 2. LISTADO DE ARCHIVOS (ls / eza)
# -----------------------------------------------------------------------------
if command -v eza &> /dev/null; then
    alias ll='eza -l --icons --git --group-directories-first'
    alias la='eza -la --icons --git --group-directories-first'
    alias lt='eza -l --sort=modified --icons --git --group-directories-first'
    alias tree='eza --tree --icons'
elif command -v lsd &> /dev/null; then
    alias ls='lsd --group-directories-first'
    alias ll='lsd -l --group-directories-first'
    alias la='lsd -la --group-directories-first'
else
    alias ll='ls -lh --color=auto --group-directories-first'
    alias la='ls -lAh --color=auto --group-directories-first'
fi

# -----------------------------------------------------------------------------
# 3. SEGURIDAD Y PREVENCIÓN DE ERRORES
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
# 4. GESTIÓN DE PAQUETES (PACMAN + YAY)
# -----------------------------------------------------------------------------
alias update='sudo pacman -Sy'
alias upgrade='sudo pacman -Syu'
alias install='sudo pacman -S --needed'
alias remove='sudo pacman -Rns'
alias search='pacman -Ss'
alias clean='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null; sudo pacman -Sc --noconfirm'
alias list-updates='pacman -Qu'
alias aur-install='yay -S --needed'
alias aur-remove='yay -Rns'
alias aur-search='yay -Ss'
alias aur-upgrade='yay -Syu'

# -----------------------------------------------------------------------------
# 5. UTILIDADES MODERNAS (Rust-based)
# -----------------------------------------------------------------------------
if command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
    alias less='bat'
fi

command -v duf &> /dev/null && alias df='duf'
command -v dust &> /dev/null && alias du='dust'
command -v procs &> /dev/null && alias ps='procs'
command -v btm &> /dev/null && alias top='btm'

# -----------------------------------------------------------------------------
# 6. VARIOS Y CONTROL DE KERNEL
# -----------------------------------------------------------------------------
alias ports='sudo ss -tulanp'
alias myip='curl -s ifconfig.me'
alias localip='ip -4 addr show | grep -oP "(?<=inet\s)\d+(\.\d+){3}"'
alias reload='source ~/.bashrc'
alias edit-bashrc='${EDITOR:-omarchy-launch-editor} ~/.bashrc'
alias cls='clear'
alias fetch='fastfetch'
alias sysinfo='fastfetch'
alias sudo='sudo '
alias grep='grep --color=auto'
alias hist='history'

# Git aliases complementarios
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gca='git commit -a'
alias gp='git pull'
alias gph='git push'
alias gF='git fetch'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# Comprobar versión de kernel activo vs última versión en kernel.org
check-kernel-update() {
    local active_kernel
    active_kernel=$(uname -r)
    local latest_kernel
    latest_kernel=$(curl -s https://www.kernel.org/releases.json 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('latest_link', {}).get('version', 'Desconocido'))" 2>/dev/null || echo "Desconocido")
    echo "================================================================="
    echo "🐧 Kernel activo en el sistema:  $active_kernel"
    echo "📌 Última versión en Kernel.org: v$latest_kernel"
    echo "================================================================="
    if [[ "$active_kernel" != *"$latest_kernel"* ]]; then
        echo "💡 Hay una versión más reciente disponible. Para actualizar ejecuta:"
        echo "   sudo pacman -Syu linux"
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
# 8. IDEs Y ACTUALIZACIONES
# -----------------------------------------------------------------------------
alias update-antigravity='sudo /usr/local/bin/update-antigravity'
alias update-antigravity-ide='sudo /usr/local/bin/update-antigravity-ide'
alias update-antigravity-cli='$HOME/.local/bin/update-antigravity-cli'

