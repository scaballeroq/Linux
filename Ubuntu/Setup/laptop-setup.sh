#!/bin/bash
# ==============================================================================
# laptop-setup.sh - Optimización de Portátil para Ubuntu Workstation (GNOME Shell 51)
# Optimizado para HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U / Vega 7)
# ==============================================================================
# Características:
#   - GNOME Shell 51 + Wayland nativo (GSettings)
#   - power-profiles-daemon integrado (gestión de energía nativa)
#   - switcheroo-control para conmutación dinámica de gráficos
#   - Touchpad multitáctil Wayland (tap-to-click, natural scroll, two-finger tap)
#   - Gestión de tapa con multimonitor (HandleLidSwitchDocked=ignore)
#   - Bluetooth FastConnectable para emparejamiento inmediato
#   - Mutter VRR (Variable Refresh Rate) y escalado fraccional
#   - Opciones CLI: --status / -s, --help / -h
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "❌ Error: Este script requiere privilegios de superusuario."
        exit 1
    fi
else
    SUDO=""
fi

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

show_help() {
    cat <<EOF
💻 Optimizador de Portátiles - Ubuntu Workstation (GNOME Shell 51 Wayland)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Aplica todas las configuraciones de energía, touchpad, VRR y servicios.
  --status, -s           Muestra el estado de batería, perfiles de energía, touchpad y Mutter.
  --help, -h             Muestra este mensaje de ayuda.

Optimizaciones incluidas:
  1. Servicios de Energía y Hardware:
     - power-profiles-daemon (gestor nativo integrado en el panel de GNOME).
     - switcheroo-control (conmutación dinámica de GPUs en Wayland).
     - brightnessctl y bluez (Bluetooth FastConnectable).
  2. Touchpad Nativo (GNOME Wayland):
     - Tap-to-click (toque para pulsar).
     - Natural scrolling (desplazamiento natural).
     - Two-finger tap para clic secundario.
  3. Políticas de Energía y Tapa:
     - No suspender al cerrar la tapa si hay monitores externos conectados (Docked=ignore).
     - Suspensión: 20 min en batería / No suspender conectado a la corriente (AC).
  4. Pantalla y Gráficos (Mutter):
     - VRR (Tasa de refresco variable) y escalado de framebuffer en Wayland.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE CONFIGURACIÓN DE PORTÁTIL - UBUNTU WORKSTATION"
    echo "================================================================="

    echo "• Batería del Sistema:"
    if [ -d /sys/class/power_supply ]; then
        for bat in /sys/class/power_supply/BAT*; do
            [ -d "$bat" ] || continue
            local name status cap
            name=$(basename "$bat")
            status=$(cat "$bat/status" 2>/dev/null || echo "n/a")
            cap=$(cat "$bat/capacity" 2>/dev/null || echo "n/a")
            echo "  - $name: $status ($cap%)"
        done
    fi

    echo "-----------------------------------------------------------------"
    echo "• Perfiles de Energía (power-profiles-daemon):"
    if command -v powerprofilesctl &>/dev/null; then
        echo "  - Perfil activo: $(powerprofilesctl get 2>/dev/null || echo 'n/a')"
    else
        echo "  - powerprofilesctl no instalado"
    fi

    echo "-----------------------------------------------------------------"
    echo "• Touchpad (GNOME GSettings):"
    echo "  - Tap-to-click:     $(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad tap-to-click 2>/dev/null || echo 'n/a')"
    echo "  - Natural Scroll:   $(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad natural-scroll 2>/dev/null || echo 'n/a')"
    echo "  - Click Method:     $(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad click-method 2>/dev/null || echo 'n/a')"

    echo "-----------------------------------------------------------------"
    echo "• Gestión de Tapa y Multimonitor:"
    echo "  - Logind lid docked: $(if [ -f /etc/systemd/logind.conf.d/lid-docked.conf ]; then echo "✅ Configurado (Docked=ignore)"; else echo "❌ Predeterminado"; fi)"

    echo "-----------------------------------------------------------------"
    echo "• Mutter Experimental Features (VRR):"
    echo "  - Features:         $(run_as_user gsettings get org.gnome.mutter experimental-features 2>/dev/null || echo '[]')"
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "💻 CONFIGURANDO OPTIMIZACIONES DE PORTÁTIL (HP ELITEBOOK / GNOME 51)"
echo "================================================================="

# 1. Instalar servicios de hardware y energía
echo "ℹ️ [1/5] Instalando utilidades de energía y hardware..."
$SUDO apt update
$SUDO apt install -y \
    power-profiles-daemon \
    switcheroo-control \
    bluez \
    brightnessctl

$SUDO systemctl enable --now power-profiles-daemon switcheroo-control

# 2. Configurar Bluetooth FastConnectable
echo "ℹ️ [2/5] Optimizando Bluetooth FastConnectable..."
if [ -f /etc/bluetooth/main.conf ]; then
    if grep -q "^FastConnectable" /etc/bluetooth/main.conf 2>/dev/null; then
        $SUDO sed -i 's/^FastConnectable.*/FastConnectable = true/' /etc/bluetooth/main.conf
    elif grep -q "^#FastConnectable" /etc/bluetooth/main.conf 2>/dev/null; then
        $SUDO sed -i 's/^#FastConnectable.*/FastConnectable = true/' /etc/bluetooth/main.conf
    else
        echo -e "\n[General]\nFastConnectable = true" | $SUDO tee -a /etc/bluetooth/main.conf > /dev/null
    fi
    $SUDO systemctl restart bluetooth 2>/dev/null || true
fi

# 3. Configurar comportamiento de cierre de tapa en multimonitor
echo "ℹ️ [3/5] Configurando systemd-logind para estaciones con monitores externos..."
$SUDO mkdir -p /etc/systemd/logind.conf.d
cat <<'EOF' | $SUDO tee /etc/systemd/logind.conf.d/lid-docked.conf > /dev/null
[Login]
# Evita suspender el portátil al cerrar la tapa si hay pantallas externas conectadas
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=ignore
EOF
$SUDO systemctl restart systemd-logind 2>/dev/null || true

# 4. Configurar Touchpad nativo en GNOME
echo "ℹ️ [4/5] Configurando gestos y comportamiento del Touchpad en GNOME..."
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad click-method 'fingers' 2>/dev/null || true

# 5. Políticas de pantalla y energía en GNOME
echo "ℹ️ [5/5] Configurando políticas de ahorro y Mutter VRR..."
# Tiempo de inactividad de pantalla: 15 min (900 seg)
run_as_user gsettings set org.gnome.desktop.session idle-delay 900 2>/dev/null || true

# Suspensión: 20 min en batería / nunca en corriente AC
run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1200 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive' 2>/dev/null || true

# Mutter VRR y escalado fraccional de monitores
run_as_user gsettings set org.gnome.mutter experimental-features "['variable-refresh-rate', 'scale-monitor-framebuffer']" 2>/dev/null || true

echo "================================================================="
echo "✅ Optimización de portátil completada con éxito en Ubuntu."
echo "================================================================="
