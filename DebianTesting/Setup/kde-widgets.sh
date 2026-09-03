#!/bin/bash
# kde-widgets.sh - Instalación y configuración de Widgets, Plasmoids y Efectos para KDE Plasma 6
# (Equivalente avanzado al ecosistema de extensiones)

set -euo pipefail

echo "🧩 Iniciando configuración de Widgets, Plasmoids y Addons de KDE Plasma..."

# 1. Instalación de paquetes de addons y widgets oficiales
echo "ℹ️ Instalando suite oficial de addons de KDE Plasma (kdeplasma-addons, plasma-systemmonitor)..."
sudo apt update
sudo apt install -y \
    kdeplasma-addons \
    plasma-systemmonitor \
    plasma-widgets-addons 2>/dev/null || sudo apt install -y kdeplasma-addons plasma-systemmonitor 2>/dev/null || true

# 2. Configuración de Klipper (Gestor Avanzado de Portapapeles Nativo de KDE)
echo "ℹ️ Optimizando Klipper (Gestor de Portapapeles)..."
KLIPPER_CFG="$HOME/.config/klipperrc"
mkdir -p "$HOME/.config"

python3 - <<'PYEOF'
import configparser
import os

cfg_path = os.path.expanduser("~/.config/klipperrc")
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

if not config.has_section("General"):
    config.add_section("General")

# Mantener historial de 100 elementos, ignorar imágenes si se desea o sincronizar
config.set("General", "MaxClipItems", "100")
config.set("General", "IgnoreSelection", "false")
config.set("General", "SyncClipboards", "true")
config.set("General", "KeepClipboardContents", "true")

with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF
echo "✅ Klipper configurado con historial persistente de 100 elementos."

# 3. Configuración de KWin Tiling (Mosaico de Ventanas) y Atajos
echo "ℹ️ Configurando atajos para Quick Tile y gestión de mosaico de ventanas..."
KWIN_CFG="$HOME/.config/kwinrc"

python3 - <<'PYEOF'
import configparser
import os

cfg_path = os.path.expanduser("~/.config/kwinrc")
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

if not config.has_section("Tiling"):
    config.add_section("Tiling")

config.set("Tiling", "padding", "4")

if not config.has_section("Windows"):
    config.add_section("Windows")

config.set("Windows", "ElectricBorders", "1")
config.set("Windows", "ElectricBorderDelay", "150")

with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF

# 4. Atajos de Teclado Globales (KGlobalShortcuts)
echo "ℹ️ Verificando atajos globales para cambio de ventanas (Alt+Tab) y Overview..."
SHORTCUTS_CFG="$HOME/.config/kglobalshortcutsrc"

python3 - <<'PYEOF'
import configparser
import os

cfg_path = os.path.expanduser("~/.config/kglobalshortcutsrc")
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

# Atajos para KWin
if not config.has_section("kwin"):
    config.add_section("kwin")

# Overview y Grid
config.set("kwin", "Overview", "Meta+W,none,Toggle Overview")
config.set("kwin", "Grid View", "Meta+G,none,Toggle Grid View")
config.set("kwin", "Walk Through Windows", "Alt+Tab,none,Walk Through Windows")

with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF

# 5. Notificar a KWin y Plasma si están activos
if pgrep -x "kwin_wayland" >/dev/null || pgrep -x "kwin_x11" >/dev/null; then
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

echo "================================================================="
echo "✅ Configuración de Widgets, Klipper y Atajos de KDE Plasma completada."
echo "💡 Disfruta de Klipper (Meta+V), Overview (Meta+W) y Tiling (Meta+T)."
echo "================================================================="
