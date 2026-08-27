#!/bin/bash
# laptop-setup.sh - Optimización para portátiles de desarrollo en Soplos Linux Tyson (Debian Testing + KDE Plasma 6)

set -euo pipefail

echo "🚀 Iniciando optimización para portátil de desarrollo en Soplos Linux Tyson..."

# 1. Herramientas de Hardware y Conectividad
echo "ℹ️ Instalando servicios de energía, bluetooth y gráficos híbridos..."
sudo apt update
sudo apt install -y \
    power-profiles-daemon \
    switcheroo-control \
    bluez \
    bluez-tools \
    brightnessctl \
    plasma-nm \
    bluedevil

# Habilitar servicios clave de portátil con systemd
echo "ℹ️ Habilitando servicios systemd para portátil..."
sudo systemctl enable --now bluetooth.service || true
sudo systemctl enable --now power-profiles-daemon.service || true
sudo systemctl enable --now switcheroo-control.service || true

# 2. Configuraciones de KDE Plasma 6 para Portátil (Touchpad, Pantalla y Energía)
echo "ℹ️ Aplicando configuraciones de Touchpad, energía y pantalla para KDE Plasma 6..."

# Configuración de Touchpad (kcminputrc)
python3 - <<'PYEOF'
import configparser
import os

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

# Configuración de políticas de energía (powermanagementprofilesrc)
python3 - <<'PYEOF'
import configparser
import os

cfg_path = os.path.expanduser("~/.config/powermanagementprofilesrc")
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

# Batería
if not config.has_section("Battery"):
    config.add_section("Battery")
if not config.has_section("Battery][SuspendSession"):
    config.add_section("Battery][SuspendSession")
config.set("Battery][SuspendSession", "idleTime", "1200000") # 20 min
config.set("Battery][SuspendSession", "suspendType", "1")     # Sleep

# AC (Conectado)
if not config.has_section("AC"):
    config.add_section("AC")
if not config.has_section("AC][SuspendSession"):
    config.add_section("AC][SuspendSession")
config.set("AC][SuspendSession", "idleTime", "3600000") # 60 min

with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF

# Configuración de renderizado en KWin (kwinrc)
python3 - <<'PYEOF'
import configparser
import os

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

echo "================================================================="
echo "✅ Configuración de portátil para Soplos Linux Tyson aplicada."
echo "================================================================="
