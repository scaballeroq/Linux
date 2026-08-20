#!/bin/bash
# shell.sh - Instalación de herramientas modernas de terminal y prompt Starship para Fedora 44

set -euo pipefail

echo "ℹ️ Instalando utilidades de terminal modernas en Fedora 44 vía DNF5..."
sudo dnf5 install -y \
    eza \
    bat \
    fzf \
    zoxide \
    ripgrep \
    fd-find \
    duf \
    dust \
    procs \
    bottom \
    curl \
    git 2>/dev/null || true

# 2. Instalación de Starship Prompt
if ! command -v starship &> /dev/null; then
    echo "ℹ️ Instalando Starship Prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    echo "✅ Starship Prompt ya está instalado."
fi

# 3. Configuración de Starship
mkdir -p ~/.config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/starship.toml" ]; then
    cp "$SCRIPT_DIR/starship.toml" ~/.config/starship.toml
    echo "✅ Configuración starship.toml copiada a ~/.config/starship.toml"
fi

# 4. Integración en .bashrc
if ! grep -q "starship init bash" ~/.bashrc 2>/dev/null; then
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
    echo "✅ Starship integrado en ~/.bashrc"
fi

if ! grep -q "zoxide init bash" ~/.bashrc 2>/dev/null; then
    echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
    echo "✅ Zoxide integrado en ~/.bashrc"
fi

echo "================================================================="
echo "✅ Entorno de terminal moderno configurado con éxito para Fedora 44."
echo "================================================================="
