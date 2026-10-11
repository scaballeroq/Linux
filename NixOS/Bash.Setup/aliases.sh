# =============================================================================
# ARCHIVO DE ALIASES (aliases.sh) - Adaptado para NixOS (KDE Plasma 6)
# =============================================================================
# Este archivo contiene atajos (aliases) para comandos utilizados frecuentemente.
# Optimizado para NixOS con Flakes, KDE Plasma 6, Wayland y utilidades Rust.

# Evitar ejecución en subshells y sesiones no interactivas (ej: scp, rsync)
[[ $- != *i* ]] && return 0 2>/dev/null || true

# 1. NAVEGACIÓN RÁPIDA
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias repo='cd ~/Workspace/Repositorios'
alias repos='cd ~/Workspace/Repositorios'
alias nixos='cd ~/Workspace/Repositorios/Linux/NixOS'
alias opensuse='cd ~/Workspace/Repositorios/Linux/OpenSuseTumbleweed'
alias tumbleweed='cd ~/Workspace/Repositorios/Linux/OpenSuseTumbleweed'
alias fedora='cd ~/Workspace/Repositorios/Linux/Fedora-Workstation'
alias cachyos='cd ~/Workspace/Repositorios/Linux/CachyOS'

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

# 5. GESTIÓN DECLARATIVA DE NIXOS (FLAKES, REBUILD Y GENERACIONES)
alias rebuild='sudo nixos-rebuild switch --flake ~/Workspace/Repositorios/Linux/NixOS'
alias switch='sudo nixos-rebuild switch --flake ~/Workspace/Repositorios/Linux/NixOS'
alias test-build='sudo nixos-rebuild test --flake ~/Workspace/Repositorios/Linux/NixOS'
alias boot-build='sudo nixos-rebuild boot --flake ~/Workspace/Repositorios/Linux/NixOS'
alias nix-update='(cd ~/Workspace/Repositorios/Linux/NixOS && nix flake update)'
alias nix-clean='sudo nix-collect-garbage -d && nix-collect-garbage -d && sudo nix-store --optimise'
alias nix-gc='sudo nix-collect-garbage -d'
alias nix-optimise='sudo nix-store --optimise'
alias generations='sudo nix-env --list-generations --profile /nix/var/nix/profiles/system'
alias rollback='sudo nixos-rebuild --rollback switch'
alias nix-search='nix search nixpkgs'
alias nshell='nix-shell -p'
alias nrun='nix run nixpkgs#'
alias edit-nixos='${EDITOR:-nano} ~/Workspace/Repositorios/Linux/NixOS/flake.nix'

# 6. UTILIDADES MODERNAS (RUST-BASED)
if command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
    alias less='bat'
fi

command -v duf &> /dev/null && alias df='duf'
command -v dust &> /dev/null && alias du='dust'
command -v procs &> /dev/null && alias ps='procs'
command -v btm &> /dev/null && alias top='btm'
command -v fastfetch &> /dev/null && alias ff='fastfetch'

# 7. VARIOS Y CONTROL DE RED
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
