#!/bin/bash
# apariencia.sh - Instalación de temas, iconos y homogeneización visual para Manjaro Linux + GNOME

set -euo pipefail

echo "ℹ️ Instalando temas e iconos (Papirus y Adwaita completos con tema Dark)..."

sudo pacman -S --needed --noconfirm \
    papirus-icon-theme \
    adwaita-icon-theme \
    gnome-themes-extra \
    adwaita-qt5 \
    adwaita-qt6 2>/dev/null || sudo pacman -S --needed --noconfirm papirus-icon-theme adwaita-icon-theme gnome-themes-extra || true

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

echo "✅ Temas, iconos e integración GTK/Qt para GNOME configurados correctamente en Manjaro."
