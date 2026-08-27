#!/bin/bash
# shell.sh - Instalacion de herramientas modernas de terminal y prompt Starship para Fedora 44

set -euo pipefail

echo "Instalando utilidades de terminal modernas en Fedora 44 via DNF5..."
sudo dnf5 install -y \
    eza \
    bat \
    fzf \
    zoxide \
    ripgrep \
    fd-find \
    duf \
    procs \
    curl \
    git \
    jq 2>/dev/null || true

# 2. Instalacion de Starship Prompt
if ! command -v starship &> /dev/null; then
    echo "Instalando Starship Prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    echo "Starship Prompt ya esta instalado."
fi

# 3. Configuracion de Starship
mkdir -p ~/.config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/starship.toml" ]; then
    cp "$SCRIPT_DIR/starship.toml" ~/.config/starship.toml
    echo "Configuracion starship.toml copiada a ~/.config/starship.toml"
fi

# 4. Integracion en .bashrc
if ! grep -q "starship init bash" ~/.bashrc 2>/dev/null; then
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
    echo "Starship integrado en ~/.bashrc"
fi

if ! grep -q "zoxide init bash" ~/.bashrc 2>/dev/null; then
    echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
    echo "Zoxide integrado en ~/.bashrc"
fi

# 5. Symlink para fd (Fedora usa fd-find)
mkdir -p ~/.local/bin
if [ -f /usr/bin/fdfind ] && [ ! -f ~/.local/bin/fd ]; then
    ln -sf /usr/bin/fdfind ~/.local/bin/fd
    echo "Symlink fd -> fdfind creado en ~/.local/bin/"
fi

echo "================================================================="
echo "Entorno de terminal moderno configurado con exito para Fedora 44."
echo "================================================================="
