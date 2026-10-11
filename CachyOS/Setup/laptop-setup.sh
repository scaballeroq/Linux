#!/bin/bash
# ==============================================================================
# laptop-setup.sh - Optimización para portátiles de desarrollo en CachyOS + GNOME
# Hardware: AMD Ryzen (HP EliteBook 855 G7) + Triple Pantalla / Escritorio fijo
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🚀 INICIANDO OPTIMIZACIÓN PARA PORTÁTIL - CACHYOS (GNOME)"
echo "================================================================="

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecución con sudo
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

# 1. Herramientas de Hardware, Conectividad y Energía
echo "ℹ️ [1/4] Instalando servicios de energía, bluetooth y utilidades de hardware..."
$SUDO pacman -S --needed --noconfirm \
    power-profiles-daemon \
    bluez \
    bluez-utils \
    brightnessctl \
    cachyos-rate-mirrors 2>/dev/null || true

# Habilitar servicios systemd esenciales
echo "ℹ️ [2/4] Habilitando servicios de sistema..."
$SUDO systemctl enable --now bluetooth.service || true
$SUDO systemctl enable --now power-profiles-daemon.service || true

# 2. Optimización Bluetooth (Nivel de batería de periféricos y reconexión rápida)
echo "ℹ️ [3/4] Configurando Bluetooth (batería de dispositivos y FastConnectable)..."
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

# 4. Configuraciones de GNOME (Touchpad, Pantalla y Energía)
echo "ℹ️ [4/4] Aplicando configuraciones de Touchpad, gestos Wayland y energía en GNOME..."

# Touchpad: Tap-to-click, desplazamiento natural, dos dedos y no suspender al teclear
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag true 2>/dev/null || true

# Energía: No suspender al estar conectado a la corriente (Workstation de desarrollo)
run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive' 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true

# Luz nocturna suave para sesiones nocturnas de desarrollo
run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000 2>/dev/null || true

# Permisos de brillo y dispositivos de entrada para el usuario
$SUDO usermod -aG video,input "$REAL_USER" 2>/dev/null || true

echo "================================================================="
echo "✅ Optimización para portátil (CachyOS + GNOME) completada con éxito."
echo "================================================================="
