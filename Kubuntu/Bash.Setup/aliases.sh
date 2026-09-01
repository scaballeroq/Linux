# =============================================================================
# ARCHIVO DE ALIASES (aliases.sh) - Kubuntu (KDE Plasma)
# =============================================================================

# 1. NAVEGACION
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias repo='cd ~/Workspace/Repositorios'
alias workspace='cd ~/Workspace'

# 2. LISTADO DE ARCHIVOS
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
    alias ll='ls -lah'
    alias la='ls -A'
    alias l='ls -CF'
    alias lt='ls -lhtr'
fi

# 3. LECTURA DE ARCHIVOS CON BAT / BATCAT
if command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
    alias less='bat'
elif command -v batcat &> /dev/null; then
    alias cat='batcat --paging=never'
    alias less='batcat'
fi

# 4. GIT
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

# 5. GESTION DE PAQUETES (APT)
alias update='sudo apt update'
alias upgrade='sudo apt upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'
alias clean='sudo apt autoremove -y && sudo apt clean'
alias list-upgradable='apt list --upgradable'

# 6. SEGURIDAD EN OPERACIONES DE ARCHIVOS
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'
alias mkdir='mkdir -p'
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# 7. UTILIDADES MODERNAS CON FALLBACK
alias h='history'
alias c='clear'
alias sudo='sudo '
alias grep='grep --color=auto'
alias ports='ss -tulanp'
alias myip='curl -s ifconfig.me'
alias localip='ip -4 addr show | grep -oP "(?<=inet\s)\d+(\.\d+){3}"'
alias reload='source ~/.bashrc'
alias edit-bashrc='${EDITOR:-nano} ~/.bashrc'
alias edit-aliases='${EDITOR:-nano} ~/.bashrc.d/aliases.sh'

if command -v duf &> /dev/null; then alias df='duf'; fi
if command -v dust &> /dev/null; then alias du='dust'; fi
if command -v procs &> /dev/null; then alias ps='procs'; fi
if command -v btm &> /dev/null; then alias top='btm'; elif command -v btop &> /dev/null; then alias top='btop'; fi
if command -v fastfetch &> /dev/null; then alias ff='fastfetch'; alias sysinfo='fastfetch'; fi

# 8. KERNEL Y HARDWARE
alias kernel-check='uname -r && cat /proc/version'
alias cpu-info='lscpu | grep -E "Model name|Architecture|CPU\(s\)"'
alias gpu-info='lspci | grep -iE "vga|3d|display"'
alias ram-info='free -h'
alias disk-info='lsblk -f'

# 9. VIRTUALIZACION (Libvirt/KVM)
alias vms='virsh list --all'
alias vmstart='virsh start'
alias vmstop='virsh shutdown'
alias vminfo='virsh dominfo'
alias vmconsole='virsh console'

# 10. PODMAN (Comandos directos)
alias p='podman'
alias pc='podman-compose'
alias pps='podman ps'
alias ppsa='podman ps -a'
alias pimg='podman images'
alias pv='podman volume ls'
alias pods='podman pod ps'
alias podsa='podman pod ps -a'
alias pclean='podman system prune -af'
