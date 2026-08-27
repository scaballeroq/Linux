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

# Detectar ejecutable de configuración de KDE (kwriteconfig6 prioritario en KDE Plasma 6)
if command -v kwriteconfig6 &>/dev/null; then
    KWRITECFG="kwriteconfig6"
elif command -v kwriteconfig5 &>/dev/null; then
    KWRITECFG="kwriteconfig5"
else
    KWRITECFG="kwriteconfig"
fi

# Configuración de Touchpad (kcminputrc)
$KWRITECFG --file kcminputrc --group "Touchpad" --key "tapToClick" "true"
$KWRITECFG --file kcminputrc --group "Touchpad" --key "naturalScroll" "true"
$KWRITECFG --file kcminputrc --group "Touchpad" --key "twoFingerTap" "2"
$KWRITECFG --file kcminputrc --group "Touchpad" --key "scrollTwoFinger" "true"

# Configuración de políticas de energía (powermanagementprofilesrc)
# Batería (Suspender tras 20 min)
$KWRITECFG --file powermanagementprofilesrc --group "Battery" --group "SuspendSession" --key "idleTime" "1200000"
$KWRITECFG --file powermanagementprofilesrc --group "Battery" --group "SuspendSession" --key "suspendType" "1"

# AC / Conectado (Suspender tras 60 min)
$KWRITECFG --file powermanagementprofilesrc --group "AC" --group "SuspendSession" --key "idleTime" "3600000"

# Configuración de renderizado en KWin (kwinrc)
$KWRITECFG --file kwinrc --group "Wayland" --key "variableRefreshRate" "Automatic"

echo "================================================================="
echo "✅ Configuración de portátil para Soplos Linux Tyson aplicada."
echo "================================================================="
