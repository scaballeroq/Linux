#!/bin/bash
# =============================================================================
# kde-plasma-customization.sh - Personalizacion KDE Plasma 6 (Ultra-Lite)
# Kubuntu - Sin compilaciones, solo paquetes APT y configuracion nativa
# =============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "Error: Este script requiere privilegios de superusuario."
        exit 1
    fi
else
    SUDO=""
fi

KWRITECFG=""
if command -v kwriteconfig6 &>/dev/null; then
    KWRITECFG="kwriteconfig6"
elif command -v kwriteconfig5 &>/dev/null; then
    KWRITECFG="kwriteconfig5"
fi

set_kconfig() {
    local file="$1"
    local group="$2"
    local key="$3"
    local value="$4"

    if [ -n "$KWRITECFG" ]; then
        $KWRITECFG --file "$file" --group "$group" --key "$key" "$value" 2>/dev/null || true
    else
        python3 - <<PYEOF
import configparser, os
cfg_path = os.path.expanduser("~/.config/${file}")
os.makedirs(os.path.dirname(cfg_path), exist_ok=True)
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')
group = "${group}"
if not config.has_section(group):
    config.add_section(group)
config.set(group, "${key}", "${value}")
with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF
    fi
}

# 1. Material You Colors (pipx)
echo "Instalando KDE Material You Colors..."
if ! command -v pipx &>/dev/null; then
    $SUDO apt install -y pipx 2>/dev/null || true
    pipx ensurepath || true
fi
pipx install --system-site-packages kde-material-you-colors --force 2>/dev/null || pipx install kde-material-you-colors --force 2>/dev/null || true

mkdir -p "$HOME/.config/autostart"
cat <<'EOF' > "$HOME/.config/autostart/kde-material-you-colors.desktop"
[Desktop Entry]
Type=Application
Exec=kde-material-you-colors --daemon
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=KDE Material You Colors Daemon
Comment=Dynamic system accent colors based on wallpaper
EOF
echo "Material You Colors configurado con autostart."

# 2. Plasmoids oficiales
echo "Instalando plasmoids oficiales..."
$SUDO apt install -y kdeplasma-addons plasma-systemmonitor 2>/dev/null || true

# 3. Configuracion de KWin
echo "Aplicando configuraciones de KWin..."
if [ -n "$KWRITECFG" ]; then
    $KWRITECFG --file kwinrc --group Plugins --key blurEnabled true 2>/dev/null || true
    $KWRITECFG --file kwinrc --group Plugins --key translucencyEnabled true 2>/dev/null || true
fi

# 4. Recargar KWin
if command -v qdbus6 &>/dev/null; then
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
elif command -v qdbus &>/dev/null; then
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

echo "================================================================="
echo "Personalizacion KDE Plasma 6 (Ultra-Lite) completada."
echo "- Material You Colors (colores dinamicos del wallpaper)"
echo "- kdeplasma-addons y plasma-systemmonitor"
echo "- Blur y translucidez nativos de KWin"
echo "================================================================="
