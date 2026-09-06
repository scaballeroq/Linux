#!/bin/bash
# ==============================================================================
# laptop-setup.sh - Optimizacion para portatiles de desarrollo en CachyOS + KDE Plasma 6
# Hardware: AMD Ryzen (HP EliteBook) + Monitores/Escritorio fijo
# ==============================================================================

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

# 1. Herramientas de Hardware, Conectividad y Energia
echo "ℹ️ [1/4] Instalando servicios de energia, bluetooth y utilidades de hardware..."
$SUDO pacman -S --needed --noconfirm \
    power-profiles-daemon \
    bluez \
    bluez-utils \
    bluedevil \
    brightnessctl \
    cachyos-rate-mirrors 2>/dev/null || true

# Habilitar servicios systemd esenciales
echo "ℹ️ [2/4] Habilitando servicios de sistema..."
$SUDO systemctl enable --now bluetooth.service || true
$SUDO systemctl enable --now power-profiles-daemon.service || true

# 2. Optimizacion Bluetooth (Nivel de bateria de perifericos y reconexion rapida)
echo "ℹ️ [3/4] Configurando Bluetooth para mostrar bateria de dispositivos en KDE..."
$SUDO mkdir -p /etc/bluetooth
if [ -f /etc/bluetooth/main.conf ]; then
    $SUDO sed -i 's/^#*Experimental *=.*/Experimental = true/' /etc/bluetooth/main.conf
    $SUDO sed -i 's/^#*FastConnectable *=.*/FastConnectable = true/' /etc/bluetooth/main.conf
else
    cat <<EOF | $SUDO tee /etc/bluetooth/main.conf > /dev/null
[General]
Experimental = true
FastConnectable = true
EOF
fi
$SUDO systemctl restart bluetooth.service 2>/dev/null || true

# 3. Comportamiento de tapa en escritorio (evita suspender con monitores externos o cargador)
$SUDO mkdir -p /etc/systemd/logind.conf.d/
cat <<EOF | $SUDO tee /etc/systemd/logind.conf.d/lid-behavior.conf > /dev/null
[Login]
HandleLidSwitchDocked=ignore
HandleLidSwitchExternalPower=ignore
EOF

# 4. Configuraciones de KDE Plasma 6 (Touchpad, Pantalla y KWin)
echo "ℹ️ [4/4] Aplicando configuraciones de Touchpad, gestos Wayland 1:1 y KWin..."
KWRITE=$(command -v kwriteconfig6 2>/dev/null || command -v kwriteconfig5 2>/dev/null || true)

if [ -n "$KWRITE" ]; then
    # Touchpad: Tap-to-click, desplazamiento natural, doble toque para arrastrar y desactivar al teclear
    run_as_user "$KWRITE" --file kcminputrc --group Touchpad --key tapToClick true 2>/dev/null || true
    run_as_user "$KWRITE" --file kcminputrc --group Touchpad --key naturalScroll true 2>/dev/null || true
    run_as_user "$KWRITE" --file kcminputrc --group Touchpad --key twoFingerTap "2" 2>/dev/null || true
    run_as_user "$KWRITE" --file kcminputrc --group Touchpad --key disableWhileTyping true 2>/dev/null || true
    run_as_user "$KWRITE" --file kcminputrc --group Touchpad --key tapAndDrag true 2>/dev/null || true
    run_as_user "$KWRITE" --file touchpadrsrc --group General --key tapToClick true 2>/dev/null || true
    run_as_user "$KWRITE" --file touchpadrsrc --group General --key naturalScroll true 2>/dev/null || true

    # KWin: Frecuencia adaptativa y gestos de escritorio en Wayland
    run_as_user "$KWRITE" --file kwinrc --group Compositing --key AdaptiveSync "true" 2>/dev/null || true
    run_as_user "$KWRITE" --file kwinrc --group Wayland --key VirtualDesktopGestures "true" 2>/dev/null || true
    run_as_user "$KWRITE" --file kglobalshortcutsrc --group kwin --key "Overview" "Meta+W,none,Toggle Overview" 2>/dev/null || true
    run_as_user "$KWRITE" --file kglobalshortcutsrc --group kwin --key "Grid" "Meta+G,none,Toggle Desktop Grid" 2>/dev/null || true

    # PowerDevil: Niveles de alerta de bateria
    run_as_user "$KWRITE" --file powerdevilrc --group BatteryManagement --key BatteryCriticalAction "1" 2>/dev/null || true
    run_as_user "$KWRITE" --file powerdevilrc --group BatteryManagement --key BatteryLowLevel "15" 2>/dev/null || true
    run_as_user "$KWRITE" --file powerdevilrc --group BatteryManagement --key BatteryCriticalLevel "5" 2>/dev/null || true

    echo "✅ Parametros de Touchpad, gestos Wayland 1:1, KWin y bateria configurados en KDE Plasma 6."
fi

# Permisos de brillo para usuarios
$SUDO usermod -aG video "$REAL_USER" 2>/dev/null || true

echo "================================================================="
echo "✅ Optimizacion para portatil (CachyOS + KDE Plasma 6) completada."
echo "💡 Recuerda reiniciar la sesion para que los cambios de KDE entren en vigor."
echo "================================================================="
