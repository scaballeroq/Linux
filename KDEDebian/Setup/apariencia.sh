#!/bin/bash
# apariencia.sh - Instalación de temas, iconos y homogeneización Qt/GTK para Debian Testing + KDE Plasma 6

set -euo pipefail

echo "ℹ️ Instalando temas e iconos (Papirus, Breeze y suite de integración Qt/GTK)..."

# Verificar si se necesita sudo
if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "❌ Error: Este script requiere privilegios de superusuario (root o sudo)."
        exit 1
    fi
else
    SUDO=""
fi

$SUDO apt update
$SUDO apt install -y \
    papirus-icon-theme \
    breeze-icon-theme \
    breeze-gtk-theme \
    kde-config-gtk-style \
    adwaita-icon-theme \
    qt6-image-formats \
    kdegraphics-thumbnailers \
    ffmpegthumbs 2>/dev/null || true

# Configuración de tema e iconos en KDE (kdeglobals y GTK)
echo "ℹ️ Configurando esquema de color Breeze Dark e iconos Papirus-Dark..."

# Aplicar esquema si plasma-apply-colorscheme está disponible
if command -v plasma-apply-colorscheme &> /dev/null; then
    plasma-apply-colorscheme BreezeDark 2>/dev/null || true
fi

# Aplicar iconos si plasma-apply-cursortheme / kwriteconfig está disponible
if command -v plasma-apply-cursortheme &> /dev/null; then
    plasma-apply-cursortheme breeze_cursors 2>/dev/null || true
fi

# Configuración directa en kdeglobals
python3 - <<'PYEOF'
import configparser
import os

cfg_path = os.path.expanduser("~/.config/kdeglobals")
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

if not config.has_section("General"):
    config.add_section("General")
config.set("General", "ColorScheme", "BreezeDark")

if not config.has_section("Icons"):
    config.add_section("Icons")
config.set("Icons", "Theme", "Papirus-Dark")

if not config.has_section("KDE"):
    config.add_section("KDE")
config.set("KDE", "widgetStyle", "Breeze")

with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF

# Configuración de temas GTK para consistencia en KDE Plasma (~/.config/gtk-3.0/settings.ini y gtk-4.0)
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
cat <<'EOF' > "$HOME/.config/gtk-3.0/settings.ini"
[Settings]
gtk-theme-name=Breeze-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=1
EOF

cat <<'EOF' > "$HOME/.config/gtk-4.0/settings.ini"
[Settings]
gtk-theme-name=Breeze-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=1
EOF

echo "✅ Temas, iconos e integración Qt/GTK configurados correctamente."
