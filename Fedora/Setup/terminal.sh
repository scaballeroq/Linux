#!/bin/bash
# terminal.sh - Instalación de Kitty Terminal y configuración con soporte de transparencia, blur e integración en KDE/Dolphin

set -e

echo "ℹ️ Instalando Kitty Terminal..."
sudo dnf5 install -y kitty

echo "✅ Kitty Terminal instalada correctamente."

# Directorio de configuración de Kitty
KITTY_CONFIG_DIR="$HOME/.config"
echo "ℹ️ Creando directorio de configuración en $KITTY_CONFIG_DIR/kitty..."
mkdir -p "$KITTY_CONFIG_DIR/kitty"

# Buscar y copiar el archivo de configuración
CONFIG_SOURCE=""
if [ -f "kitty.conf" ]; then
    CONFIG_SOURCE="kitty.conf"
elif [ -f "Setup/kitty.conf" ]; then
    CONFIG_SOURCE="Setup/kitty.conf"
fi

if [ -n "$CONFIG_SOURCE" ]; then
    echo "ℹ️ Copiando configuración de Kitty desde $CONFIG_SOURCE..."
    # Hacer una copia de respaldo si ya existe
    if [ -f "$KITTY_CONFIG_DIR/kitty/kitty.conf" ]; then
        cp "$KITTY_CONFIG_DIR/kitty/kitty.conf" "$KITTY_CONFIG_DIR/kitty/kitty.conf.bak"
        echo "💾 Respaldo de configuración anterior guardado como kitty.conf.bak"
    fi
    cp "$CONFIG_SOURCE" "$KITTY_CONFIG_DIR/kitty/kitty.conf"
    echo "✅ Configuración de Kitty instalada en $KITTY_CONFIG_DIR/kitty/kitty.conf"
else
    echo "⚠️ No se encontró el archivo kitty.conf en el repositorio para copiar."
fi

# --- Configuración de KDE Plasma 6 / Dolphin ---
# 1. Configurar Kitty como terminal por defecto del sistema KDE
if command -v kwriteconfig6 &> /dev/null; then
    echo "ℹ️ Configurando Kitty como terminal predeterminada en KDE Plasma 6..."
    kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "kitty"
    kwriteconfig6 --file kdeglobals --group General --key TerminalService "kitty.desktop"
    
    # Actualizar atajo de teclado global (Meta+T)
    kwriteconfig6 --file kglobalshortcutsrc --group kitty.desktop --key "_launch" "Meta+T,none,Kitty"
    kwriteconfig6 --file kglobalshortcutsrc --group org.kde.konsole.desktop --key "_launch" "none,none,Konsole"
elif command -v kwriteconfig5 &> /dev/null; then
    echo "ℹ️ Configurando Kitty como terminal predeterminada en KDE Plasma 5..."
    kwriteconfig5 --file kdeglobals --group General --key TerminalApplication "kitty"
    kwriteconfig5 --file kdeglobals --group General --key TerminalService "kitty.desktop"
fi

# 2. Agregar la acción "Abrir en Kitty" al menú contextual de Dolphin (Service Menu)
DOLPHIN_SERVICES_DIR="$HOME/.local/share/kio/servicemenus"
mkdir -p "$DOLPHIN_SERVICES_DIR"

cat <<EOF > "$DOLPHIN_SERVICES_DIR/openkittyhere.desktop"
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=inode/directory;
Actions=openKittyHere
X-KDE-Priority=TopLevel

[Desktop Action openKittyHere]
Name=Abrir en Kitty
Name[en]=Open Kitty Here
Icon=kitty
Exec=kitty --directory %f
EOF

chmod +x "$DOLPHIN_SERVICES_DIR/openkittyhere.desktop"
echo "✅ Acción de menú contextual 'Abrir en Kitty' instalada para Dolphin."

echo "🎉 Kitty se ha configurado con éxito con transparencia, blur e integración con Dolphin."