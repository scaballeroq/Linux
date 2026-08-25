#!/bin/bash
# apariencia.sh - Configuración de tema oscuro e iconos para Fedora 44 (KDE Plasma 6)

set -euo pipefail

echo "================================================================="
echo "🎨 Configurando apariencia visual y tema oscuro en KDE Plasma 6"
echo "================================================================="

# 1. Instalación de paquetes de iconos (Papirus/Breeze) e integración GTK en KDE
echo "ℹ️ [1/3] Instalando temas de iconos y módulo de integración GTK para KDE..."
sudo dnf5 install -y \
    papirus-icon-theme \
    breeze-icon-theme \
    breeze-gtk \
    kde-gtk-config 2>/dev/null || true

# 2. Aplicación de Tema Oscuro nativo en KDE Plasma 6 (Breeze Dark)
echo "ℹ️ [2/3] Aplicando tema oscuro nativo en KDE Plasma (Breeze Dark)..."
if command -v plasma-apply-colorscheme &>/dev/null; then
    plasma-apply-colorscheme BreezeDark 2>/dev/null || true
fi

if command -v plasma-apply-lookandfeel &>/dev/null; then
    plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || true
fi

# Configurar icono preferido en KDE Globals
if command -v kwriteconfig6 &>/dev/null; then
    kwriteconfig6 --file kdeglobals --group Icons --key Theme Papirus-Dark 2>/dev/null || true
    kwriteconfig6 --file kdeglobals --group General --key ColorScheme BreezeDark 2>/dev/null || true
fi

# 3. Sincronización visual para aplicaciones GTK3 y GTK4
echo "ℹ️ [3/3] Sincronizando tema oscuro e iconos para aplicaciones GTK..."
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

echo "================================================================="
echo "✅ Apariencia oscura y temas configurados con éxito en KDE Plasma 6."
echo "================================================================="


