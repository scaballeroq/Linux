#!/bin/bash
# ==============================================================================
# laptop-setup.sh - Optimización para portátiles de desarrollo en Fedora 44 + GNOME
# Hardware: AMD Ryzen (HP EliteBook 855 G7) + Triple Pantalla / Escritorio fijo
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🚀 INICIANDO OPTIMIZACIÓN PARA PORTÁTIL - FEDORA 44 (GNOME)"
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
echo "ℹ️ [1/5] Instalando servicios de energía, bluetooth y utilidades de hardware vía DNF5..."
$SUDO dnf5 install -y \
    power-profiles-daemon \
    switcheroo-control \
    bluez \
    bluez-tools \
    brightnessctl 2>/dev/null || true

# Habilitar servicios systemd esenciales
echo "ℹ️ [2/5] Habilitando servicios de sistema..."
$SUDO systemctl enable --now bluetooth.service 2>/dev/null || true
$SUDO systemctl enable --now switcheroo-control.service 2>/dev/null || true
$SUDO systemctl enable --now power-profiles-daemon.service 2>/dev/null || true

# 2. Optimización Bluetooth (Nivel de batería de periféricos y reconexión rápida)
echo "ℹ️ [3/5] Configurando Bluetooth (batería de dispositivos y FastConnectable)..."
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

# 3. Comportamiento de tapa en escritorio (evita suspender con monitores externos o corriente)
$SUDO mkdir -p /etc/systemd/logind.conf.d/
cat <<EOF | $SUDO tee /etc/systemd/logind.conf.d/lid-docked.conf > /dev/null
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF
$SUDO systemctl restart systemd-logind 2>/dev/null || true

# 4. Configuración de Touchpad y Energía en GNOME
echo "ℹ️ [4/5] Configurando Touchpad y ahorro energético en GNOME..."
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true

# Suspender automáticamente solo tras 30 minutos con batería
run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend' 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true

# 5. Servicio Systemd para fijar brillo al 95% en el arranque
echo "ℹ️ [5/5] Creando servicio de persistencia de brillo al 95%..."
$SUDO tee /etc/systemd/system/persist-screen-brightness.service > /dev/null << 'EOF'
[Unit]
Description=Fijar brillo de pantalla al 95% en el arranque
After=systemd-backlight@leds:*.service
Wants=systemd-backlight@leds:*.service

[Service]
Type=oneshot
ExecStart=/usr/bin/brightnessctl set 95%
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

$SUDO systemctl daemon-reload 2>/dev/null || true
$SUDO systemctl enable --now persist-screen-brightness.service 2>/dev/null || true

echo "================================================================="
echo "✅ Optimización de portátil completada para Fedora 44 (GNOME)."
echo "   - Bluetooth con FastConnectable y batería de periféricos activa."
echo "   - Cierre de tapa seguro con monitores externos o corriente."
echo "   - Touchpad: Tap-to-click y desplazamiento natural activos en GNOME."
echo "   - Servicio de brillo al 95% configurado."
echo "================================================================="
