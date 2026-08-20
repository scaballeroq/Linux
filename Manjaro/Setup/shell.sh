#!/bin/bash
# shell.sh - Instalación de herramientas modernas de terminal, plugins ZSH y prompt Starship para Manjaro Linux

set -euo pipefail

echo "ℹ️ Instalando utilidades de terminal modernas y plugins ZSH vía Pacman..."
sudo pacman -S --needed --noconfirm \
    eza \
    bat \
    fzf \
    zoxide \
    ripgrep \
    fd \
    tealdeer \
    duf \
    dust \
    procs \
    starship \
    zsh-syntax-highlighting \
    zsh-autosuggestions \
    zsh-history-substring-search 2>/dev/null || sudo pacman -S --needed --noconfirm eza bat fzf zoxide ripgrep fd duf starship || true

echo "✅ Utilidades de terminal instaladas correctamente."

# 1. Configuración Modular para ZSH (Shell por defecto en Manjaro)
mkdir -p ~/.zshrc.d
cat <<'EOF' > ~/.zshrc.d/starship.zsh
# Starship Prompt Configuration for ZSH
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi
EOF

if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "\.zshrc\.d" "$HOME/.zshrc"; then
        cat <<'EOF' >> "$HOME/.zshrc"

# Carga modular de configuraciones personalizadas
if [ -d "$HOME/.zshrc.d" ]; then
    for script in "$HOME/.zshrc.d"/*.zsh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
EOF
    fi
fi

# 2. Configuración Modular para Bash
mkdir -p ~/.bashrc.d
cat <<'EOF' > ~/.bashrc.d/starship.sh
# Starship Prompt Configuration for Bash
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi
EOF

if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "\.bashrc\.d" "$HOME/.bashrc"; then
        cat <<'EOF' >> "$HOME/.bashrc"

# Carga modular de configuraciones personalizadas
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
EOF
    fi
fi

# 3. Copiar tema personalizado de Starship
mkdir -p ~/.config
if [ -f "starship.toml" ]; then
    cp starship.toml ~/.config/starship.toml
elif [ -f "Setup/starship.toml" ]; then
    cp Setup/starship.toml ~/.config/starship.toml
fi

echo "✅ Instalación y configuración de shells (ZSH / Bash) y Starship completadas en Manjaro."
