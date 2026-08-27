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

# Configuración de tema e iconos en KDE Plasma 6 (kdeglobals y GTK)
echo "ℹ️ Configurando esquema de color Breeze Dark e iconos Papirus-Dark..."

# Aplicar esquema si plasma-apply-colorscheme está disponible
if command -v plasma-apply-colorscheme &> /dev/null; then
    plasma-apply-colorscheme BreezeDark 2>/dev/null || true
fi

# Aplicar cursores si plasma-apply-cursortheme está disponible
if command -v plasma-apply-cursortheme &> /dev/null; then
    plasma-apply-cursortheme breeze_cursors 2>/dev/null || true
fi

# Detectar ejecutable de configuración de KDE (kwriteconfig6 prioritario en KDE Plasma 6)
if command -v kwriteconfig6 &>/dev/null; then
    KWRITECFG="kwriteconfig6"
elif command -v kwriteconfig5 &>/dev/null; then
    KWRITECFG="kwriteconfig5"
else
    KWRITECFG="kwriteconfig"
fi

# Configuración directa en kdeglobals
$KWRITECFG --file kdeglobals --group "General" --key "ColorScheme" "BreezeDark"
$KWRITECFG --file kdeglobals --group "Icons" --key "Theme" "Papirus-Dark"
$KWRITECFG --file kdeglobals --group "KDE" --key "widgetStyle" "Breeze"

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

echo "✅ Temas, iconos e integración Qt/GTK configurados correctamente en Soplos Linux Tyson."
