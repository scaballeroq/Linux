#!/bin/bash
# kde-widgets.sh - Instalación y configuración de Widgets, Klipper y Efectos para KDE Plasma 6
# Soplos Linux Tyson (Debian Testing)

set -euo pipefail

echo "🧩 Iniciando configuración de Widgets, Plasmoids y Addons de KDE Plasma 6..."

# 1. Instalación de paquetes de addons y widgets oficiales
echo "ℹ️ Instalando suite oficial de addons de KDE Plasma 6 (kdeplasma-addons, plasma-systemmonitor)..."
sudo apt update
sudo apt install -y \
    kdeplasma-addons \
    plasma-systemmonitor \
    plasma-widgets-addons 2>/dev/null || sudo apt install -y kdeplasma-addons plasma-systemmonitor 2>/dev/null || true

# Detectar ejecutable de configuración de KDE (kwriteconfig6 prioritario en KDE Plasma 6)
if command -v kwriteconfig6 &>/dev/null; then
    KWRITECFG="kwriteconfig6"
elif command -v kwriteconfig5 &>/dev/null; then
    KWRITECFG="kwriteconfig5"
else
    KWRITECFG="kwriteconfig"
fi

# 2. Configuración de Klipper (Gestor Avanzado de Portapapeles Nativo de KDE)
echo "ℹ️ Optimizando Klipper (Gestor de Portapapeles)..."
$KWRITECFG --file klipperrc --group "General" --key "MaxClipItems" "100"
$KWRITECFG --file klipperrc --group "General" --key "IgnoreSelection" "false"
$KWRITECFG --file klipperrc --group "General" --key "SyncClipboards" "true"
$KWRITECFG --file klipperrc --group "General" --key "KeepClipboardContents" "true"
echo "✅ Klipper configurado con historial persistente de 100 elementos."

# 3. Configuración de KWin Tiling (Mosaico de Ventanas) y Bordes Eléctricos
echo "ℹ️ Configurando atajos para Quick Tile y gestión de mosaico de ventanas..."
$KWRITECFG --file kwinrc --group "Tiling" --key "padding" "4"
$KWRITECFG --file kwinrc --group "Windows" --key "ElectricBorders" "1"
$KWRITECFG --file kwinrc --group "Windows" --key "ElectricBorderDelay" "150"

# 4. Atajos de Teclado Globales (KGlobalShortcuts)
echo "ℹ️ Verificando atajos globales para cambio de ventanas (Alt+Tab) y Overview..."
$KWRITECFG --file kglobalshortcutsrc --group "kwin" --key "Overview" "Meta+W,none,Toggle Overview"
$KWRITECFG --file kglobalshortcutsrc --group "kwin" --key "Grid View" "Meta+G,none,Toggle Grid View"
$KWRITECFG --file kglobalshortcutsrc --group "kwin" --key "Walk Through Windows" "Alt+Tab,none,Walk Through Windows"

# 5. Notificar a KWin y Plasma si están activos
if pgrep -x "kwin_wayland" >/dev/null || pgrep -x "kwin_x11" >/dev/null; then
    if command -v qdbus6 &>/dev/null; then
        qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    elif command -v qdbus &>/dev/null; then
        qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    fi
fi

echo "================================================================="
echo "✅ Configuración de Widgets, Klipper y Atajos de KDE Plasma 6 completada."
echo "💡 Disfruta de Klipper (Meta+V), Overview (Meta+W) y Tiling (Meta+T)."
echo "================================================================="
