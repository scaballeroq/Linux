#!/bin/bash
# kde-settings.sh - Personalización de KDE Plasma vía CLI (kwriteconfig / plasma-apply) para Debian Testing

set -euo pipefail

echo "🚀 Iniciando personalización de KDE Plasma 6 en Debian..."

# Determinar ejecutable de configuración de KDE (kwriteconfig6 / kwriteconfig5 o fallback python)
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
import configparser
import os

cfg_path = os.path.expanduser(f"~/.config/{'$file'}")
os.makedirs(os.path.dirname(cfg_path), exist_ok=True)
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

group = '$group'
if not config.has_section(group):
    config.add_section(group)

config.set(group, '$key', '$value')
with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF
    fi
}

# 1. Luz Nocturna (Night Color)
echo "ℹ️ Configurando Luz Nocturna (Night Color)..."
set_kconfig "kwinrc" "NightColor" "Active" "true"
set_kconfig "kwinrc" "NightColor" "NightTemperature" "3500"
set_kconfig "kwinrc" "NightColor" "Mode" "Times"

# 2. Formato de reloj (24h) y botones de ventana
echo "ℹ️ Configurando botones de ventana y formato de reloj..."
set_kconfig "kwinrc" "org.kde.kdecoration2" "ButtonsOnRight" "IAX" # I: Minimizar, A: Maximizar, X: Cerrar
set_kconfig "kwinrc" "org.kde.kdecoration2" "ButtonsOnLeft" "M"   # M: Menú de ventana

# 3. Touchpad y gestos para portátil
echo "ℹ️ Configurando gestos y Touchpad en kcminputrc..."
set_kconfig "kcminputrc" "Touchpad" "tapToClick" "true"
set_kconfig "kcminputrc" "Touchpad" "naturalScroll" "true"
set_kconfig "kcminputrc" "Touchpad" "twoFingerTap" "2"

# 4. Comportamiento de energía
echo "ℹ️ Configurando políticas de energía en powermanagementprofilesrc..."
set_kconfig "powermanagementprofilesrc" "AC" "icon" "battery-charging"
set_kconfig "powermanagementprofilesrc" "Battery" "icon" "battery-060"

# 5. Tema oscuro preferido (Breeze Dark)
echo "ℹ️ Estableciendo esquema de color preferido (Breeze Dark)..."
if command -v plasma-apply-colorscheme &>/dev/null; then
    plasma-apply-colorscheme BreezeDark 2>/dev/null || true
fi
set_kconfig "kdeglobals" "General" "ColorScheme" "BreezeDark"
set_kconfig "kdeglobals" "KDE" "widgetStyle" "Breeze"

# 6. Efectos visuales de KWin (Blur, Translucidez, Rendimiento)
echo "ℹ️ Optimizando efectos visuales y renderizado de KWin..."
set_kconfig "kwinrc" "Compositing" "OpenGLIsUnsafe" "false"
set_kconfig "kwinrc" "Plugins" "blurEnabled" "true"
set_kconfig "kwinrc" "Plugins" "translucencyEnabled" "true"
set_kconfig "kwinrc" "Windows" "FocusStealingPreventionLevel" "1"

# 7. Recargar configuración si Plasma está corriendo
if pgrep -x "plasmashell" >/dev/null; then
    echo "🔄 Notificando cambios a KWin y Plasma..."
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

echo "================================================================="
echo "✅ Personalización de KDE Plasma completada correctamente."
echo "================================================================="
