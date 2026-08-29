#!/bin/bash
# shell.sh - Instalacion de herramientas modernas de terminal y prompt Starship para CachyOS (KDE Plasma / Wayland)

set -euo pipefail

echo "================================================================="
echo "🐚 Configurando herramientas modernas de terminal y Starship"
echo "================================================================="

# Detectar AUR helper
AUR_HELPER=""
if command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif command -v yay &> /dev/null; then
    AUR_HELPER="yay"
fi

# 1. Instalacion de utilidades modernas de terminal via Pacman
echo "ℹ️ [1/5] Instalando utilidades de terminal modernas via Pacman..."
sudo pacman -S --needed --noconfirm \
    eza \
    bat \
    fzf \
    zoxide \
    ripgrep \
    fd \
    duf \
    dust \
    procs \
    btop \
    curl \
    git \
    jq 2>/dev/null || true

# Instalar via AUR si no estan en repos oficiales
if [ -n "$AUR_HELPER" ]; then
    echo "ℹ️ Instalando herramientas adicionales via AUR..."
    $AUR_HELPER -S --needed --noconfirm \
        starship 2>/dev/null || true
fi

# 2. Instalacion de Starship Prompt
echo "ℹ️ [2/5] Verificando Starship Prompt..."
if ! command -v starship &> /dev/null; then
    echo "⬇️ Instalando Starship Prompt..."
    curl -sS https://starship.rs/install.sh | sudo sh -s -- -y -b /usr/local/bin
else
    echo "✅ Starship Prompt ya esta instalado ($(starship --version | head -n1))."
fi

# 3. Configuracion de Starship
echo "🎨 [3/5] Configurando Starship..."
mkdir -p "$HOME/.config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/starship.toml" ]; then
    cp "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
    echo "✅ Configuracion starship.toml copiada a ~/.config/starship.toml"
fi

# 4. Integracion en .bashrc
echo "⚙️ [4/5] Configurando integracion en ~/.bashrc..."
mkdir -p "$HOME/.bashrc.d"

if ! grep -q "starship init bash" "$HOME/.bashrc" 2>/dev/null; then
    echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
    echo "✅ Starship integrado en ~/.bashrc"
fi

if ! grep -q "zoxide init bash" "$HOME/.bashrc" 2>/dev/null; then
    echo 'eval "$(zoxide init bash)"' >> "$HOME/.bashrc"
    echo "✅ Zoxide integrado en ~/.bashrc"
fi

# 5. Verificacion de comandos
echo "🔗 [5/5] Verificando compatibilidad de comandos..."
mkdir -p "$HOME/.local/bin"

echo "================================================================="
echo "✅ Entorno de terminal moderno configurado con exito para CachyOS."
echo "💡 Recuerda ejecutar 'source ~/.bashrc' o abrir una nueva terminal."
echo "================================================================="
