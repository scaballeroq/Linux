# =============================================================================
# ARCHIVO DE ALIASES (aliases.sh) - Adaptado para Ubuntu
# =============================================================================
# Este archivo contiene atajos (aliases) para comandos utilizados frecuentemente.

# 1. NAVEGACIÓN RÁPIDA
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias repos='cd ~/Workspace/Repos-Linux'

# 2. MEJORAS DE 'LS' (USANDO EZA)
if command -v eza &> /dev/null; then
    #alias ls='eza --icons --git --group-directories-first'
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

# 4. GESTIÓN DE PAQUETES (APT)
alias update='sudo apt update'
alias upgrade='sudo apt upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'
alias clean='sudo apt autoremove -y && sudo apt clean'
alias list='apt list --upgradable'

# 5. UTILIDADES MODERNAS (RUST-BASED)
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
command -v du-dust &> /dev/null && alias du='du-dust'
command -v dust &> /dev/null && alias du='dust'
command -v procs &> /dev/null && alias ps='procs'
command -v btm &> /dev/null && alias top='btm'

# 6. VARIOS
alias ports='sudo ss -tulanp'
alias myip='curl -s ifconfig.me'
alias reload='source ~/.bashrc'
alias edit-bashrc='${EDITOR:-nano} ~/.bashrc'
alias edit-aliases='${EDITOR:-nano} ~/.bashrc.d/aliases.sh'
alias c='clear'
alias ff='fastfetch'
alias sysinfo='ff'

# 7. VIRTUALIZACIÓN (Libvirt/KVM)
alias vms='virsh list --all'
alias vmstart='virsh start'
alias vmstop='virsh shutdown'
alias vminfo='virsh dominfo'

echo "✅ Aliases modernizados cargados (APT, Rust tools, Git, Seguridad)"
