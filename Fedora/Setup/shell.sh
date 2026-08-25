#!/bin/bash
# shell.sh - Instalación de herramientas modernas de terminal y prompt Starship para Fedora 44 (KDE Plasma / Wayland)

set -euo pipefail

echo "================================================================="
echo "🐚 Configurando herramientas modernas de terminal y Starship"
echo "================================================================="

# 1. Instalación de utilidades modernas de terminal vía DNF5
echo "ℹ️ [1/4] Instalando utilidades de terminal modernas vía DNF5..."
sudo dnf5 install -y \
    eza \
    bat \
    fzf \
    zoxide \
    ripgrep \
    fd-find \
    duf \
    du-dust \
    procs \
    btop \
    curl \
    git 2>/dev/null || true

# 2. Instalación de Starship Prompt
echo "ℹ️ [2/4] Verificando Starship Prompt..."
if ! command -v starship &> /dev/null; then
    echo "⬇️ Instalando Starship Prompt..."
    curl -sS https://starship.rs/install.sh | sudo sh -s -- -y -b /usr/local/bin
else
    echo "✅ Starship Prompt ya está instalado ($(starship --version | head -n1))."
fi

# 3. Configuración de Starship
echo "🎨 [3/4] Configurando Starship..."
mkdir -p "$HOME/.config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/starship.toml" ]; then
    cp "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
    echo "✅ Configuración starship.toml copiada a ~/.config/starship.toml"
fi

# 4. Integración en .bashrc
echo "⚙️ [4/4] Configurando integración en ~/.bashrc..."
mkdir -p "$HOME/.bashrc.d"

if ! grep -q "starship init bash" "$HOME/.bashrc" 2>/dev/null; then
    echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
    echo "✅ Starship integrado en ~/.bashrc"
fi

if ! grep -q "zoxide init bash" "$HOME/.bashrc" 2>/dev/null; then
    echo 'eval "$(zoxide init bash)"' >> "$HOME/.bashrc"
    echo "✅ Zoxide integrado en ~/.bashrc"
fi

echo "================================================================="
echo "✅ Entorno de terminal moderno configurado con éxito para Fedora 44."
echo "💡 Recuerda ejecutar 'source ~/.bashrc' o abrir una nueva terminal."
echo "================================================================="

