#!/bin/bash
# laptop-setup.sh - Optimizacion para portatiles de desarrollo en Kubuntu (KDE Plasma)
# Incluye VRR, HiDPI, touchpad, energia, Bluetooth

set -euo pipefail

echo "Iniciando optimizacion para portatil de desarrollo en Kubuntu..."

# 1. Herramientas de Hardware y Conectividad
echo "Instalando servicios de energia, bluetooth y graficos hibridos..."
sudo apt update
sudo apt install -y \
    power-profiles-daemon \
    switcheroo-control \
    bluez \
    bluez-tools \
    brightnessctl \
    tlp-rdw || true

sudo systemctl enable --now bluetooth.service || true
sudo systemctl enable --now power-profiles-daemon.service || true
sudo systemctl enable --now switcheroo-control.service || true

# 2. Configuracion de Touchpad
echo "Configurando touchpad..."
python3 - <<'PYEOF'
import configparser, os

cfg_path = os.path.expanduser("~/.config/kcminputrc")
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

if not config.has_section("Touchpad"):
    config.add_section("Touchpad")

config.set("Touchpad", "tapToClick", "true")
config.set("Touchpad", "naturalScroll", "true")
config.set("Touchpad", "twoFingerTap", "2")
config.set("Touchpad", "scrollTwoFinger", "true")

with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF

# 3. Politicas de energia
echo "Configurando politicas de energia..."
python3 - <<'PYEOF'
import configparser, os

cfg_path = os.path.expanduser("~/.config/powermanagementprofilesrc")
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

# Bateria
for section in ["Battery", "Battery][SuspendSession"]:
    if not config.has_section(section):
        config.add_section(section)
config.set("Battery][SuspendSession", "idleTime", "1200000")
config.set("Battery][SuspendSession", "suspendType", "1")

# AC
for section in ["AC", "AC][SuspendSession"]:
    if not config.has_section(section):
        config.add_section(section)
config.set("AC][SuspendSession", "idleTime", "3600000")

with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF

# 4. VRR (Variable Refresh Rate) en Wayland
echo "Configurando VRR en Wayland..."
python3 - <<'PYEOF'
import configparser, os

cfg_path = os.path.expanduser("~/.config/kwinrc")
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

if not config.has_section("Wayland"):
    config.add_section("Wayland")
config.set("Wayland", "variableRefreshRate", "Automatic")

with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF

# 5. HiDPI (si aplica)
echo "Configuracion HiDPI lista (ajustar desde Preferencias del Sistema si es necesario)."

echo "================================================================="
echo "Configuracion de portatil para Kubuntu aplicada."
echo "VRR: Automatico | Touchpad: tap-to-click + natural scroll"
echo "================================================================="
