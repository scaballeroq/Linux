#!/bin/bash
# laptop-setup.sh - Optimizacion para portatiles de desarrollo en CachyOS + KDE Plasma 6

set -euo pipefail

echo "================================================================="
echo "🚀 INICIANDO OPTIMIZACION PARA PORTATIL - CACHYOS (KDE PLASMA 6)"
echo "================================================================="

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no esta disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecucion con sudo
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# 1. Herramientas de Hardware, Conectividad y Gestion de Energia
echo "ℹ️ [1/3] Instalando servicios de energia, bluetooth y graficos hibridos..."
$SUDO pacman -S --needed --noconfirm \
    power-profiles-daemon \
    switcheroo-control \
    bluez \
    bluez-utils \
    brightnessctl \
    acpid \
    cachyos-rate-mirrors 2>/dev/null || true

# Habilitar servicios systemd para portatil
echo "ℹ️ [2/3] Habilitando servicios de sistema para portatil..."
$SUDO systemctl enable --now bluetooth.service || true
$SUDO systemctl enable --now power-profiles-daemon.service || true
$SUDO systemctl enable --now switcheroo-control.service || true
$SUDO systemctl enable --now acpid.service 2>/dev/null || true

# 2. Configuraciones de KDE Plasma 6 para Portatil (Touchpad, Pantalla y Energia)
echo "ℹ️ [3/3] Aplicando configuraciones de Touchpad, KWin y PowerDevil para KDE Plasma 6..."

KWRITE=$(command -v kwriteconfig6 2>/dev/null || command -v kwriteconfig5 2>/dev/null || true)

if [ -n "$KWRITE" ]; then
    # Gestos y Touchpad: Tap-to-click y desplazamiento natural
    run_as_user "$KWRITE" --file kcminputrc --group Touchpad --key tapToClick true 2>/dev/null || true
    run_as_user "$KWRITE" --file kcminputrc --group Touchpad --key naturalScroll true 2>/dev/null || true
    run_as_user "$KWRITE" --file kcminputrc --group Touchpad --key twoFingerTap "2" 2>/dev/null || true
    run_as_user "$KWRITE" --file touchpadrsrc --group General --key tapToClick true 2>/dev/null || true
    run_as_user "$KWRITE" --file touchpadrsrc --group General --key naturalScroll true 2>/dev/null || true

    # KWin: Frecuencia de actualizacion adaptativa / VRR en Wayland
    run_as_user "$KWRITE" --file kwinrc --group Compositing --key AdaptiveSync "true" 2>/dev/null || true

    # PowerDevil: Gestion inteligente de suspension y bateria
    run_as_user "$KWRITE" --file powerdevilrc --group BatteryManagement --key BatteryCriticalAction "1" 2>/dev/null || true
    run_as_user "$KWRITE" --file powerdevilrc --group BatteryManagement --key BatteryLowLevel "15" 2>/dev/null || true
    run_as_user "$KWRITE" --file powerdevilrc --group BatteryManagement --key BatteryCriticalLevel "5" 2>/dev/null || true

    echo "✅ Parametros de Touchpad, KWin y bateria configurados en KDE Plasma 6."
fi

# Permisos de brillo para usuarios sin requerir root en cada cambio
$SUDO usermod -aG video "$REAL_USER" 2>/dev/null || true

echo "================================================================="
echo "✅ Optimizacion para portatil (CachyOS + KDE Plasma 6) completada."
echo "💡 Recuerda reiniciar la sesion para que los cambios de KDE entren en vigor."
echo "================================================================="
