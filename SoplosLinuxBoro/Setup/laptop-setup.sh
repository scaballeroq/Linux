#!/bin/bash
# ==============================================================================
# laptop-setup.sh - Optimización de Portátil para Soplos Linux Boro Workstation (GNOME Shell 46 / 50 / 51)
# Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U / Vega 8)
# Compatible con Soplos Linux Boro 24.04 LTS (GNOME 46), Soplos Linux Boro 26.04 LTS (GNOME 50) y superiores
# ==============================================================================
# Características:
#   - GNOME Shell (46/50/51) + Wayland nativo (GSettings)
#   - power-profiles-daemon integrado (gestor de energía oficial de GNOME)
#   - switcheroo-control para conmutación dinámica de gráficos
#   - Touchpad multitáctil Wayland (tap-to-click, natural scroll, two-finger tap)
#   - Gestión de tapa con multimonitor (HandleLidSwitchDocked=ignore)
#   - Bluetooth FastConnectable para emparejamiento inmediato
#   - Detección dinámica de Mutter: VRR, escalado fraccional y escalado nativo XWayland
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

get_gnome_version() {
    local ver
    ver=$(gnome-shell --version 2>/dev/null | awk '{print $3}')
    if [ -z "$ver" ]; then
        ver=$(run_as_user gnome-shell --version 2>/dev/null | awk '{print $3}' || echo "")
    fi
    echo "${ver:-Desconocida}"
}

get_os_description() {
    if [ -f /etc/os-release ]; then
        grep "^PRETTY_NAME=" /etc/os-release | cut -d= -f2 | tr -d '"'
    else
        echo "Soplos Linux Boro"
    fi
}

show_help() {
    cat <<EOF
💻 Optimizador de Portátiles - Soplos Linux Boro Workstation (GNOME Shell 46 / 50 / 51 Wayland)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Aplica todas las configuraciones de energía, touchpad, Mutter y servicios.
  --status, -s           Muestra el estado de batería, perfiles de energía, touchpad y Mutter.
  --help, -h             Muestra este mensaje de ayuda.

Compatibilidad de Versiones:
  • Soplos Linux Boro 24.04 LTS (GNOME Shell 46 Wayland)
  • Soplos Linux Boro 26.04 LTS (GNOME Shell 50 Wayland)
  • Soplos Linux Boro Rolling / GNOME Shell 51 Wayland

Optimizaciones incluidas:
  1. Servicios de Energía y Hardware:
     - power-profiles-daemon (gestor nativo integrado en el panel de GNOME).
     - switcheroo-control (conmutación dinámica de GPUs en Wayland).
     - brightnessctl y bluez (Bluetooth FastConnectable).
  2. Touchpad Nativo (GNOME Wayland):
     - Tap-to-click (toque para pulsar).
     - Natural scrolling (desplazamiento natural).
     - Two-finger tap para clic secundario (click-method 'fingers').
  3. Políticas de Energía y Tapa:
     - No suspender al cerrar la tapa si hay monitores externos conectados (Docked=ignore).
     - Suspensión: 20 min en batería / No suspender conectado a la corriente (AC).
     - Perfil de ahorro automático (power-saver) con batería baja.
  4. Pantalla y Gráficos (Mutter):
     - Detección dinámica y aplicación según capacidades de la versión de GNOME / Mutter:
       * VRR (variable-refresh-rate) en GNOME 46
       * Escalado fraccional (scale-monitor-framebuffer) en GNOME 46 / 50 / 51
       * Escalado nativo XWayland (xwayland-native-scaling) en GNOME 50 / 51
EOF
}

configure_mutter_features() {
    if run_as_user gsettings list-keys org.gnome.mutter 2>/dev/null | grep -q "^experimental-features$"; then
        local range features=()
        range=$(run_as_user gsettings range org.gnome.mutter experimental-features 2>/dev/null || true)

        # scale-monitor-framebuffer (escalado fraccional en Wayland: GNOME 46 / 50 / 51)
        if echo "$range" | grep -q "scale-monitor-framebuffer"; then
            features+=("'scale-monitor-framebuffer'")
        fi

        # variable-refresh-rate (VRR: presente como experimental en GNOME 46)
        if echo "$range" | grep -q "variable-refresh-rate"; then
            features+=("'variable-refresh-rate'")
        fi

        # xwayland-native-scaling (escalado nítido para apps X11 en Wayland: GNOME 50 / 51)
        if echo "$range" | grep -q "xwayland-native-scaling"; then
            features+=("'xwayland-native-scaling'")
        fi

        if [ ${#features[@]} -gt 0 ]; then
            local features_str
            features_str=$(IFS=, ; echo "[${features[*]}]")
            run_as_user gsettings set org.gnome.mutter experimental-features "$features_str" 2>/dev/null || true
            echo "  - Mutter experimental-features aplicadas: $features_str"
        else
            echo "  - Mutter no requiere experimental-features adicionales en esta versión."
        fi
    else
        echo "  - Esquema experimental-features no disponible en esta versión de Mutter."
    fi
}

show_status() {
    local gnome_ver os_name
    gnome_ver=$(get_gnome_version)
    os_name=$(get_os_description)

    echo "================================================================="
    echo "🔍 ESTADO DE CONFIGURACIÓN DE PORTÁTIL - SOPLOS LINUX BORO WORKSTATION"
    echo "================================================================="
    echo "• Sistema Operativo:     $os_name"
    echo "• GNOME Shell:           $gnome_ver (Wayland)"
    echo "• Hardware:              HP ProBook 455 G10 (AMD Ryzen 7 7730U / Vega 8)"
    echo "-----------------------------------------------------------------"
    echo "• Batería del Sistema:"
    if [ -d /sys/class/power_supply ]; then
        local found_bat=false
        for bat in /sys/class/power_supply/BAT*; do
            [ -d "$bat" ] || continue
            found_bat=true
            local name status cap
            name=$(basename "$bat")
            status=$(cat "$bat/status" 2>/dev/null || echo "n/a")
            cap=$(cat "$bat/capacity" 2>/dev/null || echo "n/a")
            echo "  - $name: $status ($cap%)"
        done
        if [ "$found_bat" = "false" ]; then
            echo "  - No se detectaron baterías físicas en el sistema"
        fi
    fi

    echo "-----------------------------------------------------------------"
    echo "• Perfiles de Energía (power-profiles-daemon):"
    if command -v powerprofilesctl &>/dev/null; then
        echo "  - Perfil activo:        $(powerprofilesctl get 2>/dev/null || echo 'n/a')"
    else
        echo "  - powerprofilesctl no instalado"
    fi
    if run_as_user gsettings list-keys org.gnome.settings-daemon.plugins.power 2>/dev/null | grep -q "^power-saver-profile-on-low-battery$"; then
        local ps_low
        ps_low=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.power power-saver-profile-on-low-battery 2>/dev/null || echo 'n/a')
        echo "  - Ahorro en baja bat.:  $ps_low"
    fi

    echo "-----------------------------------------------------------------"
    echo "• Touchpad (GNOME GSettings):"
    echo "  - Tap-to-click:         $(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad tap-to-click 2>/dev/null || echo 'n/a')"
    echo "  - Natural Scroll:       $(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad natural-scroll 2>/dev/null || echo 'n/a')"
    echo "  - Click Method:         $(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad click-method 2>/dev/null || echo 'n/a')"
    echo "  - Two-Finger Scroll:    $(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled 2>/dev/null || echo 'n/a')"

    echo "-----------------------------------------------------------------"
    echo "• Gestión de Tapa y Multimonitor:"
    echo "  - Logind lid docked:    $(if [ -f /etc/systemd/logind.conf.d/lid-docked.conf ]; then echo "✅ Configurado (Docked=ignore)"; else echo "❌ Predeterminado"; fi)"
    if run_as_user gsettings list-keys org.gnome.settings-daemon.plugins.power 2>/dev/null | grep -q "^lid-close-suspend-with-external-monitor$"; then
        local gnome_lid_ext
        gnome_lid_ext=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.power lid-close-suspend-with-external-monitor 2>/dev/null || echo 'n/a')
        if [ "$gnome_lid_ext" = "false" ]; then
            echo "  - GNOME lid docked:     ✅ No suspender con monitores externos (false)"
        else
            echo "  - GNOME lid docked:     ⚠️ Suspende con monitores ($gnome_lid_ext)"
        fi
    else
        echo "  - GNOME lid docked:     ✅ Gestionado por systemd-logind (nativo en GNOME 43+ / 50)"
    fi

    echo "-----------------------------------------------------------------"
    echo "• Mutter Wayland & Características Gráficas:"
    if run_as_user gsettings list-keys org.gnome.mutter 2>/dev/null | grep -q "^experimental-features$"; then
        local cur_feat range_feat
        cur_feat=$(run_as_user gsettings get org.gnome.mutter experimental-features 2>/dev/null || echo '[]')
        range_feat=$(run_as_user gsettings range org.gnome.mutter experimental-features 2>/dev/null | grep -v "^flags$" | tr '\n' ' ' || echo 'n/a')
        echo "  - Features activas:     $cur_feat"
        echo "  - Features soportadas:  $range_feat"
    else
        echo "  - Features:             ✅ Integrado nativamente en Mutter Wayland"
    fi
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

GNOME_CUR_VER=$(get_gnome_version)
OS_CUR_NAME=$(get_os_description)

echo "================================================================="
echo "💻 CONFIGURANDO OPTIMIZACIONES DE PORTÁTIL"
echo "   $OS_CUR_NAME | GNOME Shell $GNOME_CUR_VER"
echo "   Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)"
echo "================================================================="

# 1. Instalar servicios de hardware y energía (idempotente)
echo "ℹ️ [1/5] Verificando utilidades de energía y hardware..."
REQUIRED_PKGS=(
    power-profiles-daemon
    switcheroo-control
    bluez
    brightnessctl
)
MISSING_PKGS=()
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "  ⬇️ Instalando paquetes faltantes: ${MISSING_PKGS[*]}..."
    $SUDO apt-get update -qq
    $SUDO apt-get install -y "${MISSING_PKGS[@]}"
    echo "  ✅ Paquetes instalados con éxito."
else
    echo "  ✅ Paquetes de energía y hardware ya instalados."
fi

# Si tlp estuviese instalado, desactivarlo para evitar conflictos con power-profiles-daemon
if systemctl is-active --quiet tlp 2>/dev/null || systemctl is-enabled --quiet tlp 2>/dev/null; then
    echo "⚠️ Desactivando TLP para permitir que power-profiles-daemon gestione la energía..."
    $SUDO systemctl stop tlp 2>/dev/null || true
    $SUDO systemctl mask tlp 2>/dev/null || true
fi

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
# IMPORTANTE: NUNCA usar 'restart systemd-logind' en un entorno gráfico (Wayland/X11).
# Reiniciar logind destruye las sesiones activas de usuario, revoca los descriptores DRM
# y de dispositivos de entrada (evdev) a Mutter/GNOME Shell, provocando el cierre abrupto
# de sesión y el bloqueo completo (deadlock) de la máquina al intentar reingresar.
# Se utiliza 'reload' (SIGHUP) que recarga la configuración sin terminar procesos ni sesiones.
$SUDO systemctl reload systemd-logind 2>/dev/null || true

# 4. Configurar Touchpad nativo en GNOME
echo "ℹ️ [4/5] Configurando gestos y comportamiento del Touchpad en GNOME Shell ($GNOME_CUR_VER)..."
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad click-method 'fingers' 2>/dev/null || true

# 5. Políticas de pantalla y energía en GNOME
echo "ℹ️ [5/5] Configurando políticas de ahorro de energía y características de Mutter..."
# Tiempo de inactividad de pantalla: 15 min (900 seg)
run_as_user gsettings set org.gnome.desktop.session idle-delay 900 2>/dev/null || true

# Suspensión: 20 min en batería / nunca en corriente AC
run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1200 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true
run_as_user gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive' 2>/dev/null || true

# Evitar suspender con tapa cerrada si hay monitor externo conectado (a nivel de GNOME Shell si la clave está disponible)
if run_as_user gsettings list-keys org.gnome.settings-daemon.plugins.power 2>/dev/null | grep -q "^lid-close-suspend-with-external-monitor$"; then
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power lid-close-suspend-with-external-monitor false 2>/dev/null || true
fi

# Activar modo de bajo consumo automático cuando la batería esté baja (si soportado)
if run_as_user gsettings list-keys org.gnome.settings-daemon.plugins.power 2>/dev/null | grep -q "^power-saver-profile-on-low-battery$"; then
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power power-saver-profile-on-low-battery true 2>/dev/null || true
fi

# Configuración adaptativa de Mutter (VRR, escalado fraccional y escalado XWayland)
configure_mutter_features

echo "================================================================="
echo "✅ Optimización de portátil completada con éxito en $OS_CUR_NAME (GNOME $GNOME_CUR_VER)."
echo "================================================================="
