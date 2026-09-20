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

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$REAL_UID/bus}" \
            "$@"
    else
        "$@"
    fi
}

# 1. Herramientas de Hardware, Conectividad y Energía
echo "ℹ️ [1/6] Instalando utilidades de hardware, bluetooth y brillo vía DNF5..."
# Nota: En Fedora 41+, el daemon predeterminado de perfiles de energía es tuned-ppd (en conflicto con power-profiles-daemon).
$SUDO dnf5 install -y \
    switcheroo-control \
    bluez \
    bluez-tools \
    brightnessctl 2>/dev/null || true

# Si ni tuned-ppd ni power-profiles-daemon están instalados, asegurar tuned-ppd
if ! rpm -q tuned-ppd &>/dev/null && ! rpm -q power-profiles-daemon &>/dev/null; then
    $SUDO dnf5 install -y tuned-ppd 2>/dev/null || true
fi

# 2. Habilitar servicios systemd esenciales
echo "ℹ️ [2/6] Habilitando servicios de sistema..."
$SUDO systemctl enable --now bluetooth.service 2>/dev/null || true
$SUDO systemctl enable --now switcheroo-control.service 2>/dev/null || true

# Habilitar el gestor de perfiles de energía correspondiente (tuned-ppd o power-profiles-daemon)
if systemctl list-unit-files tuned-ppd.service &>/dev/null; then
    $SUDO systemctl enable --now tuned.service tuned-ppd.service 2>/dev/null || true
elif systemctl list-unit-files power-profiles-daemon.service &>/dev/null; then
    $SUDO systemctl enable --now power-profiles-daemon.service 2>/dev/null || true
fi

# 3. Optimización Bluetooth (Nivel de batería de periféricos y reconexión rápida)
echo "ℹ️ [3/6] Configurando Bluetooth (batería de dispositivos y FastConnectable)..."
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

# 4. Comportamiento de tapa en escritorio (evita suspender con monitores externos o corriente)
echo "ℹ️ [4/6] Configurando comportamiento de la tapa (docking / pantallas externas)..."
$SUDO mkdir -p /etc/systemd/logind.conf.d/
cat <<EOF | $SUDO tee /etc/systemd/logind.conf.d/lid-docked.conf > /dev/null
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF
# NOTA: No se debe reiniciar systemd-logind en caliente durante una sesión gráfica activa,
# ya que desconecta los asientos y dispositivos de entrada en Wayland, forzando la pantalla de bloqueo y congelando el sistema.
# La configuración se aplicará automáticamente en el próximo reinicio.

# 5. Configuración de Touchpad y Energía en GNOME
echo "ℹ️ [5/6] Configurando Touchpad y ahorro energético en GNOME..."
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true

# Suspender automáticamente solo tras 30 minutos con batería
run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend' 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true

# 6. Servicio Systemd para fijar brillo al 95% en el arranque
echo "ℹ️ [6/6] Creando servicio de persistencia de brillo al 95%..."
$SUDO tee /etc/systemd/system/persist-screen-brightness.service > /dev/null << 'EOF'
[Unit]
Description=Fijar brillo de pantalla al 95% en el arranque
After=graphical.target multi-user.target

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
echo "   - Cierre de tapa seguro configurado (se aplicará tras reiniciar)."
echo "   - Touchpad: Tap-to-click y desplazamiento natural activos en GNOME."
echo "   - Servicio de brillo al 95% configurado."
echo "================================================================="
