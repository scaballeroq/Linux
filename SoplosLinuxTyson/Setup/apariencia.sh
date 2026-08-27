#!/bin/bash
# apariencia.sh - Instalación de temas, iconos y homogeneización Qt/GTK para Soplos Linux Tyson (Debian Testing + KDE Plasma 6)

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

# 2. Integración y modo oscuro para aplicaciones GTK 3 y GTK 4
echo "ℹ️ Configurando preferencia de modo oscuro para GTK 3 y GTK 4..."
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

# GTK 3 settings
cat <<'EOF' > "$HOME/.config/gtk-3.0/settings.ini"
[Settings]
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=1
EOF

# GTK 4 settings
cat <<'EOF' > "$HOME/.config/gtk-4.0/settings.ini"
[Settings]
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=1
EOF

# Sincronización con GNOME / Flatpak / Libadwaita vía GSettings
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
fi

echo "✅ Iconos Papirus-Dark e integración de modo oscuro GTK configurados respetando tu tema actual."
