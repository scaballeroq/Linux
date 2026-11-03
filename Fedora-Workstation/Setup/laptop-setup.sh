#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  laptop-setup.sh - Optimización de Portátil para Fedora 45 Workstation
#  HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon / GNOME Wayland / Triple Monitor)
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

if [[ $EUID -eq 0 ]]; then
    REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER:-root}")}"
else
    REAL_USER="${USER:-$(whoami)}"
fi
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
REAL_UID=$(id -u "$REAL_USER")

run_as_user() {
    if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
        sudo -u "$REAL_USER" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${REAL_UID}/bus" \
            XDG_RUNTIME_DIR="/run/user/${REAL_UID}" \
            "$@"
    else
        "$@"
    fi
}

DNF_BIN="dnf5"
command -v dnf5 &>/dev/null || DNF_BIN="dnf"

LOGIND_DROPIN_DIR="/etc/systemd/logind.conf.d"
LOGIND_DROPIN_FILE="$LOGIND_DROPIN_DIR/99-laptop-docked.conf"

RUN_ALL=true
RUN_POWER=false
RUN_TOUCHPAD=false
RUN_DISPLAY=false
RUN_LOGIND=false
RUN_BLUETOOTH=false
ACTION="run"

show_help() {
    cat << EOF
${BOLD}💻 Optimizador de Portátil para Desarrollo - Fedora 45 Workstation (GNOME Wayland)${NC}

Configura perfiles de energía (tuned-ppd / power-profiles-daemon + amd-pstate-epp),
gestos Touchpad Wayland, topología multimonitor (DP-3, DP-4, eDP-1), cierre de tapa
inteligente en estación acoplada (logind) y Bluetooth FastConnectable.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)   Ejecuta todos los módulos de optimización de portátil
  -s, --status       Muestra telemetría de batería, CPU EPP, pantallas DRM y energía
  --power            Configura solo gestión de energía y perfil balanced/performance
  --touchpad         Configura solo Touchpad Wayland, tap-to-click y NumLock
  --display          Configura solo Mutter VRR, escalado y luz nocturna
  --logind           Configura solo cierre de tapa inteligente (systemd-logind reload seguro)
  --bluetooth        Configura solo Bluetooth AutoEnable y FastConnectable
  -h, --help         Muestra esta ayuda
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  💻 ${BOLD}ESTADO Y TELEMETRÍA DEL PORTÁTIL - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    # 1. CPU & AMD P-State EPP
    local drv gov epp
    drv=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo "N/A")
    gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "N/A")
    epp=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo "N/A")
    echo -e "${BOLD}⚡ Procesador y Energía:${NC}"
    echo -e "  • Driver CPU / Gobernador:   ${CYAN}${drv}${NC} / ${CYAN}${gov}${NC} (EPP: ${BOLD}${epp}${NC})"
    if command -v powerprofilesctl &>/dev/null; then
        echo -e "  • Perfil energético activo:  ${GREEN}$(powerprofilesctl get 2>/dev/null || echo 'N/A')${NC}"
    fi

    # 2. Batería (Salud en Wh)
    for bat in /sys/class/power_supply/BAT*; do
        if [[ -d "$bat" ]]; then
            local status cap e_full e_design health_pct
            status=$(cat "$bat/status" 2>/dev/null || echo "N/A")
            cap=$(cat "$bat/capacity" 2>/dev/null || echo "N/A")
            e_full=$(cat "$bat/energy_full" 2>/dev/null || cat "$bat/charge_full" 2>/dev/null || echo 0)
            e_design=$(cat "$bat/energy_full_design" 2>/dev/null || cat "$bat/charge_full_design" 2>/dev/null || echo 0)
            if [[ "$e_design" -gt 0 ]]; then
                health_pct=$(awk "BEGIN {printf \"%.1f\", ($e_full / $e_design) * 100}")
                local wh_full wh_design
                wh_full=$(awk "BEGIN {printf \"%.1f\", $e_full / 1000000}")
                wh_design=$(awk "BEGIN {printf \"%.1f\", $e_design / 1000000}")
                echo -e "  • Batería ($(basename "$bat")):            ${GREEN}${cap}% (${status})${NC} | Salud: ${CYAN}${health_pct}%${NC} (${wh_full} Wh / ${wh_design} Wh)"
            else
                echo -e "  • Batería ($(basename "$bat")):            ${GREEN}${cap}% (${status})${NC}"
            fi
        fi
    done

    # 3. Topología DRM Multi-Monitor
    echo ""
    echo -e "${BOLD}🖥️  Conectores de Pantalla DRM (Wayland / amdgpu):${NC}"
    for conn in /sys/class/drm/card*-*; do
        if [[ -f "$conn/status" ]]; then
            local st name
            st=$(cat "$conn/status")
            name=$(basename "$conn" | sed 's/^card[0-9]*-//')
            if [[ "$st" == "connected" ]]; then
                local mode
                mode=$(head -n1 "$conn/modes" 2>/dev/null || echo "1920x1080")
                echo -e "  • $(printf '%-12s' "$name"):              ${GREEN}Conectado (${mode})${NC}"
            fi
        fi
    done

    # 4. Logind & Touchpad & Bluetooth
    echo ""
    echo -e "${BOLD}🔧 Subsistemas de Portátil:${NC}"
    if [[ -f "$LOGIND_DROPIN_FILE" ]]; then
        echo -e "  • Cierre de tapa (Docked):   ${GREEN}Configurado (${LOGIND_DROPIN_FILE})${NC}"
    else
        echo -e "  • Cierre de tapa (Docked):   ${YELLOW}Por defecto del sistema${NC}"
    fi

    local tap_click
    tap_click=$(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad tap-to-click 2>/dev/null || echo "N/A")
    echo -e "  • Touchpad Tap-to-Click:     ${CYAN}${tap_click}${NC}"

    if systemctl is-active --quiet bluetooth 2>/dev/null; then
        echo -e "  • Servicio Bluetooth:        ${GREEN}Activo${NC}"
    else
        echo -e "  • Servicio Bluetooth:        ${YELLOW}Inactivo${NC}"
    fi
    echo -e "${BOLD}======================================================================${NC}"
}

setup_power() {
    log_info "Configurando gestión de energía en Fedora 45 Workstation..."
    # En Fedora 41-45 tuned-ppd o power-profiles-daemon proveen powerprofilesctl
    if ! command -v powerprofilesctl &>/dev/null; then
        sudo "$DNF_BIN" install -y tuned-ppd 2>/dev/null || sudo "$DNF_BIN" install -y power-profiles-daemon
    fi

    # Asegurar conflictos desactivados (TLP interfiere con tuned-ppd / power-profiles-daemon)
    if systemctl is-active --quiet tlp 2>/dev/null; then
        sudo systemctl disable --now tlp 2>/dev/null || true
    fi

    if systemctl list-unit-files | grep -q "^tuned-ppd.service"; then
        sudo systemctl enable --now tuned.service tuned-ppd.service 2>/dev/null || true
    elif systemctl list-unit-files | grep -q "^power-profiles-daemon.service"; then
        sudo systemctl enable --now power-profiles-daemon.service 2>/dev/null || true
    fi

    # Ajustes de energía en GNOME: no suspender conectado a CA, suspender a los 20 min en batería
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1200
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power idle-dim true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive'
    run_as_user gsettings set org.gnome.desktop.interface show-battery-percentage true

    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set balanced 2>/dev/null || true
    fi
    log_ok "Gestión de energía configurada."
}

setup_touchpad() {
    log_info "Optimizando Touchpad y periféricos en GNOME Wayland..."
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad click-method 'fingers'
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true
    run_as_user gsettings set org.gnome.desktop.peripherals.keyboard remember-numlock-state true
    log_ok "Touchpad Wayland y teclado configurados."
}

setup_display() {
    log_info "Configurando Mutter Wayland para topología multimonitor (DP-3, DP-4, eDP-1)..."
    run_as_user gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'variable-refresh-rate', 'xwayland-native-scaling']" 2>/dev/null || \
        run_as_user gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'variable-refresh-rate']" 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter workspaces-only-on-primary false
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000
    log_ok "Mutter Wayland y multimonitor optimizados."
}

setup_logind() {
    log_info "Configurando cierre de tapa inteligente en estación acoplada ($LOGIND_DROPIN_FILE)..."
    sudo mkdir -p "$LOGIND_DROPIN_DIR"
    sudo tee "$LOGIND_DROPIN_FILE" > /dev/null << 'EOF'
# ==============================================================================
#  Configuración de Tapa para Portátil HP ProBook 455 G10 (Triple Monitor)
#  Suspende en batería solitaria; ignora cierre de tapa con monitores externos o CA
# ==============================================================================
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
LidSwitchIgnoreInhibited=yes
EOF

    # IMPORTANTE: NUNCA usar 'systemctl restart systemd-logind' dentro de una sesión gráfica activa
    sudo systemctl reload systemd-logind 2>/dev/null || sudo kill -HUP "$(pidof systemd-logind)" 2>/dev/null || true
    log_ok "systemd-logind recargado de forma segura sin interrumpir la sesión Wayland."
}

setup_bluetooth() {
    log_info "Optimizando pila Bluetooth BlueZ (AutoEnable y FastConnectable)..."
    local bt_conf="/etc/bluetooth/main.conf"
    if [[ -f "$bt_conf" ]]; then
        sudo sed -i 's/^#*AutoEnable\s*=.*/AutoEnable=true/' "$bt_conf"
        sudo sed -i 's/^#*FastConnectable\s*=.*/FastConnectable=true/' "$bt_conf"
    fi
    sudo systemctl enable --now bluetooth.service 2>/dev/null || true
    log_ok "Bluetooth configurado y activo."
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status) ACTION="status"; shift ;;
        --power)     RUN_ALL=false; RUN_POWER=true; shift ;;
        --touchpad)  RUN_ALL=false; RUN_TOUCHPAD=true; shift ;;
        --display)   RUN_ALL=false; RUN_DISPLAY=true; shift ;;
        --logind)    RUN_ALL=false; RUN_LOGIND=true; shift ;;
        --bluetooth) RUN_ALL=false; RUN_BLUETOOTH=true; shift ;;
        -h|--help)   show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

if [[ "$ACTION" == "status" ]]; then
    show_status
    exit 0
fi

if [[ "$RUN_ALL" == true ]]; then
    setup_power
    setup_touchpad
    setup_display
    setup_logind
    setup_bluetooth
else
    [[ "$RUN_POWER" == true ]]     && setup_power
    [[ "$RUN_TOUCHPAD" == true ]]  && setup_touchpad
    [[ "$RUN_DISPLAY" == true ]]   && setup_display
    [[ "$RUN_LOGIND" == true ]]    && setup_logind
    [[ "$RUN_BLUETOOTH" == true ]] && setup_bluetooth
fi

log_ok "Optimización de portátil para Fedora 45 Workstation completada."
show_status
