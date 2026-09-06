#!/bin/bash
# ==============================================================================
# laptop-setup.sh - Optimizacion para portatiles de desarrollo en CachyOS + Niri
# Hardware: AMD Ryzen (HP EliteBook) / Intel + Monitores / Escritorio fijo
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🚀 INICIANDO OPTIMIZACION PARA PORTATIL - CACHYOS (NIRI + NOCTALIA)"
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
    blueman \
    brightnessctl \
    cachyos-rate-mirrors 2>/dev/null || true

# Habilitar servicios systemd esenciales
echo "ℹ️ [2/4] Habilitando servicios de sistema..."
$SUDO systemctl enable --now bluetooth.service || true
$SUDO systemctl enable --now power-profiles-daemon.service || true

# 2. Optimizacion Bluetooth (Nivel de bateria de perifericos y reconexion rapida)
echo "ℹ️ [3/4] Configurando Bluetooth para reportar nivel de bateria (Noctalia Shell / Blueman)..."
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

# 4. Ajuste de permisos de brillo y Touchpad en Niri
echo "ℹ️ [4/4] Verificando permisos de brillo de pantalla y configuracion de Touchpad..."
$SUDO usermod -aG video "$REAL_USER" 2>/dev/null || true

# Verificar que Niri tenga configurado el bloque de Touchpad con tap y desplazamiento natural
NIRI_CONF="$USER_HOME/.config/niri/config.kdl"
if [ -f "$NIRI_CONF" ]; then
    if ! grep -q "touchpad" "$NIRI_CONF" 2>/dev/null; then
        echo "  ℹ️ Añadiendo bloque de Touchpad optimizado a ~/.config/niri/config.kdl..."
        cat << 'EOF' | run_as_user tee -a "$NIRI_CONF" > /dev/null

input {
    touchpad {
        tap
        natural-scroll
        dwt
        accel-speed 0.2
    }
}
EOF
        echo "  ✅ Touchpad (tap-to-click, natural-scroll) añadido a config.kdl"
    else
        echo "  ✅ Touchpad ya configurado en ~/.config/niri/config.kdl"
    fi
fi

echo "================================================================="
echo "✅ Optimizacion para portatil (CachyOS + Niri + Noctalia) completada."
echo "💡 Disfruta de una gestion de bateria, brillo y conectividad optimizada."
echo "================================================================="
