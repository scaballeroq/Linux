#!/bin/bash
# ==============================================================================
# VS CODE SETUP (vscode.sh) - Omarchy (Arch Linux + Hyprland)
# Instalación de Visual Studio Code optimizado para Wayland nativo
# ==============================================================================

set -euo pipefail

echo "ℹ️ Instalando Visual Studio Code para Arch Linux..."

if command -v yay &> /dev/null; then
    yay -S --needed --noconfirm visual-studio-code-bin
elif command -v paru &> /dev/null; then
    paru -S --needed --noconfirm visual-studio-code-bin
else
    echo "ℹ️ Instalando paquete oficial 'code' desde repositorios de Arch Linux..."
    sudo pacman -S --needed --noconfirm code
fi

# Configurar flags Wayland para Electron si no existen
mkdir -p "$HOME/.config"
if [ ! -f "$HOME/.config/code-flags.conf" ]; then
    cat <<'EOF' > "$HOME/.config/code-flags.conf"
--ozone-platform-hint=auto
--enable-features=WaylandWindowDecorations
EOF
    echo "  ✅ Flags Wayland configurados en ~/.config/code-flags.conf"
fi

echo ""
echo "✅ Visual Studio Code instalado y configurado para Wayland."
