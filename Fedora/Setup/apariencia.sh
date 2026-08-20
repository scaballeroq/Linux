#!/bin/bash
# apariencia.sh - Instalación de temas, iconos y homogeneización visual para Fedora 44 + GNOME

set -euo pipefail

echo "ℹ️ Instalando temas e iconos (Papirus y Adwaita completos con tema Dark)..."

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

$SUDO dnf5 install -y \
    papirus-icon-theme \
    adwaita-icon-theme \
    adwaita-qt5 \
    adwaita-qt6 \
    gnome-themes-extra 2>/dev/null || true

# Configuración de tema Adwaita Dark y Papirus-Dark en gsettings
if command -v gsettings &> /dev/null; then
    echo "ℹ️ Configurando tema oscuro Adwaita e iconos Papirus-Dark en GNOME..."
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
fi

# Configuración de temas GTK (~/.config/gtk-3.0/settings.ini y gtk-4.0)
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
cat <<'EOF' > "$HOME/.config/gtk-3.0/settings.ini"
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=1
EOF

cat <<'EOF' > "$HOME/.config/gtk-4.0/settings.ini"
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=1
EOF

echo "✅ Temas, iconos e integración GTK/Qt para GNOME configurados correctamente."
