#!/bin/bash
# terminal.sh - Instalación y configuración de Kitty para Arch Linux con GNOME

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🖥️ Instalando Kitty Terminal..."

# Instalar Kitty
sudo pacman -S --noconfirm kitty

# Configurar Kitty
echo "ℹ️ Configurando Kitty..."
mkdir -p ~/.config/kitty
cp "$SCRIPT_DIR/kitty.conf" ~/.config/kitty/kitty.conf

# Establecer Kitty como terminal predeterminada en GNOME
echo "ℹ️ Estableciendo Kitty como terminal predeterminada en GNOME..."
if command -v gsettings &> /dev/null; then
    gsettings set org.gnome.desktop.default-applications.terminal exec kitty
    gsettings set org.gnome.desktop.default-applications.terminal exec-arg ""
fi

# Crear acción de contexto para Nautilus (si está instalado)
echo "ℹ️ Creando acción de contexto para Nautilus..."
NAUTILUS_SCRIPTS_DIR="$HOME/.local/share/nautilus/scripts"
mkdir -p "$NAUTILUS_SCRIPTS_DIR"

cat << 'EOF' > "$NAUTILUS_SCRIPTS_DIR/Open Kitty Here"
#!/bin/bash
kitty --working-directory "$NAUTILUS_SCRIPT_CURRENT_URI"
EOF
chmod +x "$NAUTILUS_SCRIPTS_DIR/Open Kitty Here"

echo "✅ Kitty Terminal configurado correctamente"
