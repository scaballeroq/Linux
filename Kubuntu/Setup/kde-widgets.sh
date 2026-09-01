#!/bin/bash
# kde-widgets.sh - Widgets, Plasmoids y Atajos para KDE Plasma 6 en Kubuntu

set -euo pipefail

echo "Configurando Widgets, Klipper y Atajos de KDE Plasma..."

# 1. Instalar addons oficiales
echo "Instalando kdeplasma-addons y plasma-systemmonitor..."
sudo apt update
sudo apt install -y kdeplasma-addons plasma-systemmonitor 2>/dev/null || true

# 2. Klipper (historial de portapapeles)
echo "Configurando Klipper..."
python3 - <<'PYEOF'
import configparser, os

cfg_path = os.path.expanduser("~/.config/klipperrc")
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

if not config.has_section("General"):
    config.add_section("General")

config.set("General", "MaxClipItems", "100")
config.set("General", "IgnoreSelection", "false")
config.set("General", "SyncClipboards", "true")
config.set("General", "KeepClipboardContents", "true")

with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF
echo "Klipper configurado con historial de 100 elementos."

# 3. KWin Tiling
echo "Configurando KWin Tiling..."
python3 - <<'PYEOF'
import configparser, os

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

# 4. Atajos globales
echo "Configurando atajos globales..."
python3 - <<'PYEOF'
import configparser, os

cfg_path = os.path.expanduser("~/.config/kglobalshortcutsrc")
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

if not config.has_section("kwin"):
    config.add_section("kwin")

config.set("kwin", "Overview", "Meta+W,none,Toggle Overview")
config.set("kwin", "Grid View", "Meta+G,none,Toggle Grid View")
config.set("kwin", "Walk Through Windows", "Alt+Tab,none,Walk Through Windows")

with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF

# 5. Recargar KWin
if pgrep -x "kwin_wayland" >/dev/null || pgrep -x "kwin_x11" >/dev/null; then
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

echo "================================================================="
echo "Widgets, Klipper y Atajos de KDE Plasma configurados."
echo "Klipper: Meta+V | Overview: Meta+W | Grid: Meta+G"
echo "================================================================="
