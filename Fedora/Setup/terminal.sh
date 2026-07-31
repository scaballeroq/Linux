#!/bin/bash
# terminal.sh - Instalación de Kitty Terminal y configuración con soporte de transparencia, blur e integración en KDE/Dolphin

set -e

echo "ℹ️ Instalando Kitty Terminal y dependencias de integración..."
sudo dnf5 install -y kitty nautilus-python

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

# --- Configuración de Entornos de Escritorio ---

# ==========================================
# KDE Plasma / Dolphin
# ==========================================
if command -v kwriteconfig6 &> /dev/null || command -v kwriteconfig5 &> /dev/null; then
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
fi

# ==========================================
# GNOME / Nautilus
# ==========================================
if command -v gsettings &> /dev/null; then
    echo "ℹ️ Configurando Kitty como terminal predeterminada en GNOME..."
    gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty' 2>/dev/null || true
    
    # Agregar la acción "Abrir en Kitty" al menú contextual principal de Nautilus usando nautilus-python
    NAUTILUS_PYTHON_DIR="$HOME/.local/share/nautilus-python/extensions"
    mkdir -p "$NAUTILUS_PYTHON_DIR"
    
    cat <<'EOF' > "$NAUTILUS_PYTHON_DIR/open-kitty.py"
import os
from gi.repository import Nautilus, GObject

class OpenKittyExtension(GObject.GObject, Nautilus.MenuProvider):
    def _open_kitty(self, file):
        if file and file.is_directory():
            path = file.get_location().get_path()
        elif file:
            path = file.get_parent_location().get_path()
        else:
            path = os.environ.get("PWD", os.path.expanduser("~"))
            
        if path:
            os.system(f"kitty --directory \"{path}\" &")
        else:
            os.system("kitty &")

    def menu_activate_cb(self, menu, file):
        self._open_kitty(file)

    def menu_background_activate_cb(self, menu, file):
        self._open_kitty(file)

    def get_file_items(self, *args):
        files = args[-1] if args else []
        if not files or len(files) != 1 or not files[0].is_directory():
            return []
        
        item = Nautilus.MenuItem(name='KittyExtension::Open_Dir',
                                 label='Abrir en Kitty',
                                 tip='Abrir terminal Kitty aquí')
        item.connect('activate', self.menu_activate_cb, files[0])
        return [item]

    def get_background_items(self, *args):
        file = args[-1] if args else None
        item = Nautilus.MenuItem(name='KittyExtension::Open_Bg',
                                 label='Abrir en Kitty',
                                 tip='Abrir terminal Kitty aquí')
        item.connect('activate', self.menu_background_activate_cb, file)
        return [item]
EOF

    echo "✅ Extensión 'Abrir en Kitty' instalada en el menú principal de Nautilus."
    echo "⚠️  Nota para GNOME: Es posible que necesites reiniciar Nautilus ejecutando 'nautilus -q' para ver los cambios."
fi

echo "🎉 Kitty se ha configurado con éxito con transparencia, blur e integración con el entorno de escritorio."