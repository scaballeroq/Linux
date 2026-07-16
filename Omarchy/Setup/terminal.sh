#!/bin/bash
# terminal.sh - Instalación y configuración de Kitty para Omarchy (Arch Linux + Hyprland)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🖥️ Instalando Kitty Terminal..."

# Instalar Kitty
sudo pacman -S --noconfirm --needed kitty

# Configurar Kitty
echo "ℹ️ Configurando Kitty..."
mkdir -p ~/.config/kitty
cp "$SCRIPT_DIR/kitty.conf" ~/.config/kitty/kitty.conf

# Establecer Kitty como terminal predeterminada en Hyprland (xdg-terminal-exec)
echo "ℹ️ Estableciendo Kitty como terminal predeterminada..."
TERMINALS_LIST="$HOME/.config/xdg-terminals.list"

# Crear archivo si no existe
if [ ! -f "$TERMINALS_LIST" ]; then
    mkdir -p "$(dirname "$TERMINALS_LIST")"
    cat << 'EOF' > "$TERMINALS_LIST"
# Terminal emulator preference order for xdg-terminal-exec
# The first found and valid terminal will be used
EOF
fi

# Agregar kitty como primera opción si no está ya configurado
if ! grep -q "kitty.desktop" "$TERMINALS_LIST" 2>/dev/null; then
    # Crear archivo temporal con kitty.desktop después de los comentarios
    {
        grep '^#' "$TERMINALS_LIST"
        echo "kitty.desktop"
        grep -v '^#' "$TERMINALS_LIST" | grep -v '^$'
    } > "${TERMINALS_LIST}.tmp"
    mv "${TERMINALS_LIST}.tmp" "$TERMINALS_LIST"
    echo "✅ Kitty agregado como terminal predeterminado"
else
    echo "ℹ️ Kitty ya está configurado como terminal predeterminado"
fi

# Reiniciar terminal para aplicar cambios
if command -v omarchy &> /dev/null; then
    echo "ℹ️ Reiniciando terminal..."
    omarchy restart terminal
fi

echo "✅ Kitty Terminal configurado correctamente"
