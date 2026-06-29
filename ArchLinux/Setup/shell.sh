#!/bin/bash
# shell.sh - Instalación de utilidades modernas de terminal para Arch Linux

set -e

echo "🐚 Instalando utilidades modernas de terminal..."

# Instalar utilidades desde repositorios oficiales
sudo pacman -S --noconfirm --needed eza bat fzf zoxide ripgrep fd tldr duf dust bottom procs starship lazygit

# Copiar configuración de Starship
mkdir -p ~/.config
cp "$(dirname "$0")/starship.toml" ~/.config/starship.toml

# Añadir inicialización de Starship a la shell
if [ -f ~/.bashrc ]; then
    if ! grep -q 'starship init' ~/.bashrc 2>/dev/null; then
        echo '' >> ~/.bashrc
        echo '# Starship Prompt' >> ~/.bashrc
        echo 'eval "$(starship init bash)"' >> ~/.bashrc
        echo "✅ Starship añadido a ~/.bashrc"
    fi
fi

if [ -f ~/.zshrc ]; then
    if ! grep -q 'starship init' ~/.zshrc 2>/dev/null; then
        echo '' >> ~/.zshrc
        echo '# Starship Prompt' >> ~/.zshrc
        echo 'eval "$(starship init zsh)"' >> ~/.zshrc
        echo "✅ Starship añadido a ~/.zshrc"
    fi
fi

echo "✅ Utilidades de terminal instaladas correctamente"
