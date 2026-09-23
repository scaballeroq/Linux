#!/bin/bash
# ==============================================================================
# laptop-setup.sh - Optimización para portátiles de desarrollo en openSUSE Tumbleweed
# Entorno: KDE Plasma 6 (Wayland) + AMD Ryzen (HP EliteBook 855 G7)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🚀 INICIANDO OPTIMIZACIÓN PARA PORTÁTIL - OPENSUSE TUMBLEWEED (KDE 6)"
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
echo "ℹ️ [1/6] Instalando utilidades de hardware, bluetooth y brillo vía Zypper..."
$SUDO zypper --non-interactive install -y \
    power-profiles-daemon \
    switcheroo-control \
    bluez \
    brightnessctl 2>/dev/null || true

# 2. Habilitar servicios systemd esenciales
echo "ℹ️ [2/6] Habilitando servicios de sistema..."
$SUDO systemctl enable --now bluetooth.service 2>/dev/null || true
$SUDO systemctl enable --now power-profiles-daemon.service 2>/dev/null || true
$SUDO systemctl enable --now switcheroo-control.service 2>/dev/null || true

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

# 5. Configuración de Touchpad y Energía en KDE Plasma 6
echo "ℹ️ [5/6] Configurando Touchpad y ahorro energético en KDE Plasma 6..."
# Touchpad: Tap-to-click y desplazamiento natural
run_as_user kwriteconfig6 --file kcminputrc --group "parameters" --key "TapToClick" true 2>/dev/null || true
run_as_user kwriteconfig6 --file kcminputrc --group "parameters" --key "NaturalScroll" true 2>/dev/null || true

# Energía en KDE PowerDevil: Suspender automáticamente tras 30 min con batería, no suspender con corriente
run_as_user kwriteconfig6 --file powermanagementprofilesrc --group "Battery" --group "SuspendSession" --key "idleTime" 1800000 2>/dev/null || true
run_as_user kwriteconfig6 --file powermanagementprofilesrc --group "Battery" --group "SuspendSession" --key "suspendType" 1 2>/dev/null || true
run_as_user kwriteconfig6 --file powermanagementprofilesrc --group "AC" --group "SuspendSession" --key "idleTime" 0 2>/dev/null || true

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

# Autostart XDG para asegurar 95% de brillo al inicio de sesión de usuario
run_as_user mkdir -p "$USER_HOME/.config/autostart"
cat << 'EOF' | run_as_user tee "$USER_HOME/.config/autostart/set-screen-brightness.desktop" > /dev/null
[Desktop Entry]
Type=Application
Name=Set Brightness 95%
Exec=/usr/bin/brightnessctl set 95%
Hidden=false
NoDisplay=false
Comment=Ajusta el brillo de la pantalla al 95% al iniciar sesión
EOF

echo "================================================================="
echo "✅ Optimización de portátil completada para openSUSE Tumbleweed (KDE 6)."
echo "   - Bluetooth con FastConnectable y batería de periféricos activa."
echo "   - Cierre de tapa seguro configurado (se aplicará tras reiniciar)."
echo "   - Touchpad: Tap-to-click y desplazamiento natural activos en KDE."
echo "   - Servicio de brillo al 95% configurado."
echo "================================================================="
