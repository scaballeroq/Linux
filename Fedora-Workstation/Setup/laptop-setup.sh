#!/usr/bin/env bash
# ==============================================================================
#  laptop-setup.sh - Optimización Integral de Portátil para Fedora 45 Workstation
#  Sistema: Fedora Workstation (GNOME Shell 51+ Wayland / Mutter)
#  Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / 32 GB RAM DDR4)
#  Topología: Triple Monitor Full HD 1080p (DP-3, DP-4, eDP-1)
# ==============================================================================
#  Características:
#   - Detección y gestión de perfil de energía vía TuneD / PPD / D-Bus
#   - AMD P-State EPP (energy_performance_preference) y telemetría térmica por hardware
#   - Telemetría avanzada de batería BAT0 (capacidad %, salud Wh, ciclos, consumo en W)
#   - Cierre de tapa inteligente en systemd-logind (HandleLidSwitchDocked=ignore)
#   - Recarga segura de logind (reload / SIGHUP) sin matar la sesión gráfica Wayland
#   - Gestos Touchpad Wayland (tap-to-click, natural scroll, tap-and-drag, two-finger)
#   - Persistencia de estado de bloque numérico (HP ProBook 455 G10 teclado numérico)
#   - Mutter Wayland: espacios de trabajo independientes en multimonitor y Night Light
#   - BlueZ: FastConnectable, AutoEnable y reporte de batería de dispositivos (Experimental)
#   - Operación rootless prioritaria (gsettings/D-Bus directos sin sudo innecesario)
#   - Opciones CLI modulares: --status, --power, --touchpad, --display, --logind, --bluetooth
# ==============================================================================

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y FORMATO VISUAL (ANSI-C Quoting)
# ------------------------------------------------------------------------------
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

# ------------------------------------------------------------------------------
# 2. PRIVILEGIOS Y ENTORNO DE USUARIO
# ------------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    if ! command -v sudo &>/dev/null; then
        echo -e "${RED}❌ Error: 'sudo' no está disponible.${NC}" >&2
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

# Ejecución garantizada en el contexto de sesión de usuario (D-Bus / dconf / Wayland)
run_as_user() {
    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$REAL_UID}"
    local dbus_addr="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$runtime_dir/bus}"
    if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            "$@"
    else
        env \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            "$@"
    fi
}

DNF_BIN="dnf5"
command -v dnf5 &>/dev/null || DNF_BIN="dnf"

LOGIND_DROPIN_DIR="/etc/systemd/logind.conf.d"
LOGIND_DROPIN_FILE="$LOGIND_DROPIN_DIR/99-laptop-docked.conf"

# Banderas de ejecución modular
RUN_ALL=true
RUN_POWER=false
RUN_TOUCHPAD=false
RUN_DISPLAY=false
RUN_LOGIND=false
RUN_BLUETOOTH=false
ACTION="run"

# ------------------------------------------------------------------------------
# 3. AYUDA CLI
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}💻 Optimizador de Portátil para Desarrollo - Fedora 45 Workstation (GNOME Wayland)${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / 32 GB RAM / NVMe / Triple Pantalla)

Configura perfiles de energía (TuneD / tuned-ppd + AMD P-State EPP),
gestos Touchpad Wayland, topología multimonitor (DP-3, DP-4, eDP-1), cierre de tapa
inteligente en estación acoplada (logind) y pila Bluetooth BlueZ con FastConnectable.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)    Ejecuta todos los módulos de optimización y muestra diagnóstico final
  -s, --status        Muestra diagnóstico completo (batería, salud Wh, AMD EPP, DRM y térmicas)
  -p, --power         Configura solo gestión de energía (TuneD / PPD, AMD EPP y timeouts GNOME)
  -t, --touchpad      Configura solo gestos Wayland del touchpad y memoria del teclado numérico
  -d, --display       Configura solo Mutter Wayland, espacios multimonitor y Luz Nocturna
  -l, --logind        Configura solo cierre de tapa inteligente (systemd-logind reload seguro)
  -b, --bluetooth     Configura solo Bluetooth (AutoEnable, FastConnectable y batería de periféricos)
  -h, --help          Muestra este mensaje de ayuda
EOF
}

# ------------------------------------------------------------------------------
# 4. DIAGNÓSTICO Y TELEMETRÍA DEL SISTEMA (--status)
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  💻 ${BOLD}ESTADO Y TELEMETRÍA DEL PORTÁTIL - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    # 1. Sistema Operativo y Hardware
    local os_desc gnome_ver
    os_desc=$(grep "^PRETTY_NAME=" /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "Fedora 45 Workstation")
    gnome_ver=$(gnome-shell --version 2>/dev/null | awk '{print $3}' || echo "N/A")
    if [[ "$gnome_ver" == "N/A" ]]; then
        gnome_ver=$(run_as_user gnome-shell --version 2>/dev/null | awk '{print $3}' || echo "N/A")
    fi

    echo -e "${BOLD}🖥️  Sistema y Entorno Gráfico:${NC}"
    echo -e "  • Sistema Operativo:         ${CYAN}${os_desc}${NC} (Kernel $(uname -r))"
    echo -e "  • Entorno de Escritorio:     ${CYAN}GNOME Shell ${gnome_ver}${NC} (${XDG_SESSION_TYPE:-wayland} / Mutter)"
    echo -e "  • Hardware de la Estación:   ${BOLD}HP ProBook 455 G10${NC} (AMD Ryzen 7 7730U / Radeon Vega 8)"

    # 2. CPU AMD P-State, Gobernador y Perfil de Energía
    echo ""
    echo -e "${BOLD}⚡ Procesador, Térmica y Perfiles de Energía:${NC}"
    local drv gov epp
    drv=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo "N/A")
    gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "N/A")
    epp=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo "N/A")
    echo -e "  • Driver CPU / Gobernador:   ${CYAN}${drv}${NC} / ${CYAN}${gov}${NC} (EPP: ${BOLD}${epp}${NC})"

    # Sensores térmicos por hardware (k10temp CPU y amdgpu)
    local cpu_temp="N/A" gpu_temp="N/A"
    for h in /sys/class/hwmon/hwmon*; do
        if [[ -d "$h" ]]; then
            local hname
            hname=$(cat "$h/name" 2>/dev/null || echo "")
            if [[ "$hname" == "k10temp" ]]; then
                local t
                t=$(cat "$h/temp1_input" 2>/dev/null || echo 0)
                if [[ "$t" -gt 0 ]]; then
                    cpu_temp=$(awk "BEGIN {printf \"%.1f°C\", $t / 1000}")
                fi
            elif [[ "$hname" == "amdgpu" ]]; then
                local t
                t=$(cat "$h/temp1_input" 2>/dev/null || echo 0)
                if [[ "$t" -gt 0 ]]; then
                    gpu_temp=$(awk "BEGIN {printf \"%.1f°C\", $t / 1000}")
                fi
            fi
        fi
    done
    echo -e "  • Temperaturas (Hardware):   CPU: ${GREEN}${cpu_temp}${NC} | GPU: ${GREEN}${gpu_temp}${NC}"

    # Perfil activo: D-Bus PPD + TuneD backend
    local ppd_profile="N/A"
    if command -v powerprofilesctl &>/dev/null; then
        ppd_profile=$(powerprofilesctl get 2>/dev/null || echo "N/A")
    elif command -v gdbus &>/dev/null; then
        local raw_val
        raw_val=$(gdbus call --system --dest net.hadess.PowerProfiles --object-path /net/hadess/PowerProfiles \
            --method org.freedesktop.DBus.Properties.Get "net.hadess.PowerProfiles" "ActiveProfile" 2>/dev/null || true)
        if [[ -n "$raw_val" ]]; then
            ppd_profile=$(echo "$raw_val" | cut -d"'" -f2 2>/dev/null || echo "N/A")
        fi
    fi

    local tuned_profile="N/A"
    if command -v tuned-adm &>/dev/null; then
        tuned_profile=$(tuned-adm active 2>/dev/null | sed 's/^Current active profile: //' || echo "N/A")
    fi
    echo -e "  • Perfil Activo (GNOME):     ${GREEN}${ppd_profile}${NC} (Backend TuneD: ${CYAN}${tuned_profile}${NC})"

    # 3. Batería BAT0 y Alimentación Eléctrica
    echo ""
    echo -e "${BOLD}🔋 Batería y Alimentación:${NC}"
    local ac_st="${YELLOW}Desconocido${NC}"
    if [[ -f /sys/class/power_supply/AC/online ]]; then
        local ac_val
        ac_val=$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo 0)
        if [[ "$ac_val" == "1" ]]; then
            ac_st="${GREEN}🔌 Conectado (Corriente Alterna / Base Dock)${NC}"
        else
            ac_st="${YELLOW}🔋 Desconectado (En Batería)${NC}"
        fi
    fi
    echo -e "  • Adaptador de Corriente:    $ac_st"

    for bat in /sys/class/power_supply/BAT*; do
        if [[ -d "$bat" ]]; then
            local bname status cap cycles e_now e_full e_design p_now
            bname=$(basename "$bat")
            status=$(cat "$bat/status" 2>/dev/null || echo "N/A")
            cap=$(cat "$bat/capacity" 2>/dev/null || echo "N/A")
            cycles=$(cat "$bat/cycle_count" 2>/dev/null || echo "N/A")
            e_now=$(cat "$bat/energy_now" 2>/dev/null || cat "$bat/charge_now" 2>/dev/null || echo 0)
            e_full=$(cat "$bat/energy_full" 2>/dev/null || cat "$bat/charge_full" 2>/dev/null || echo 0)
            e_design=$(cat "$bat/energy_full_design" 2>/dev/null || cat "$bat/charge_full_design" 2>/dev/null || echo 0)
            p_now=$(cat "$bat/power_now" 2>/dev/null || cat "$bat/current_now" 2>/dev/null || echo 0)

            if [[ "$e_design" -gt 0 ]]; then
                local health_pct wh_now wh_full wh_design
                health_pct=$(awk "BEGIN {printf \"%.1f\", ($e_full / $e_design) * 100}")
                wh_now=$(awk "BEGIN {printf \"%.1f\", $e_now / 1000000}")
                wh_full=$(awk "BEGIN {printf \"%.1f\", $e_full / 1000000}")
                wh_design=$(awk "BEGIN {printf \"%.1f\", $e_design / 1000000}")
                echo -e "  • Estado Batería (${bname}):      ${GREEN}${cap}% (${status})${NC} | Restante: ${CYAN}${wh_now} Wh${NC}"
                echo -e "  • Salud y Capacidad:         ${CYAN}${health_pct}%${NC} (${wh_full} Wh actual / ${wh_design} Wh diseño) | Ciclos: ${BOLD}${cycles}${NC}"
            else
                echo -e "  • Batería (${bname}):             ${GREEN}${cap}% (${status})${NC}"
            fi

            if [[ "$p_now" -gt 0 ]]; then
                local w_now
                w_now=$(awk "BEGIN {printf \"%.2f\", $p_now / 1000000}")
                echo -e "  • Consumo Instantáneo:       ${BOLD}${w_now} W${NC}"
            fi
        fi
    done

    # 4. Topología DRM Multi-Monitor
    echo ""
    echo -e "${BOLD}🖥️  Topología de Pantallas DRM (Wayland / amdgpu):${NC}"
    local drm_connected=()
    for conn in /sys/class/drm/card*-*; do
        if [[ -f "$conn/status" ]]; then
            local st cname
            st=$(cat "$conn/status")
            cname=$(basename "$conn" | sed 's/^card[0-9]*-//')
            if [[ "$st" == "connected" ]]; then
                local mode
                mode=$(head -n1 "$conn/modes" 2>/dev/null || echo "1920x1080")
                echo -e "  • $(printf '%-14s' "$cname"):            ${GREEN}Conectado (${mode})${NC}"
                drm_connected+=("$cname")
            fi
        fi
    done

    if echo "${drm_connected[*]}" | grep -qE "DP-[34]"; then
        echo -e "  • Modo de Trabajo:           ${GREEN}✅ Multimonitor Externo Activo (Topología Triple Pantalla DP-3 + DP-4 + eDP-1)${NC}"
    elif [[ ${#drm_connected[@]} -gt 0 ]]; then
        echo -e "  • Modo de Trabajo:           ${CYAN}ℹ️  Portátil Autónomo (Pantalla Integrada FHD eDP-1)${NC}"
    else
        echo -e "  • Modo de Trabajo:           ${YELLOW}No se detectaron conectores DRM activos${NC}"
    fi

    # 5. Logind, Touchpad, Mutter y Bluetooth
    echo ""
    echo -e "${BOLD}🔧 Subsistemas de Portátil y Periféricos:${NC}"
    if [[ -f "$LOGIND_DROPIN_FILE" ]]; then
        echo -e "  • Cierre de tapa (Docked):   ${GREEN}Configurado (${LOGIND_DROPIN_FILE})${NC}"
    else
        echo -e "  • Cierre de tapa (Docked):   ${YELLOW}Por defecto del sistema${NC}"
    fi

    local tap_click nat_scroll tap_drag numlock
    tap_click=$(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad tap-to-click 2>/dev/null || echo "N/A")
    nat_scroll=$(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad natural-scroll 2>/dev/null || echo "N/A")
    tap_drag=$(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad tap-and-drag 2>/dev/null || echo "N/A")
    numlock=$(run_as_user gsettings get org.gnome.desktop.peripherals.keyboard remember-numlock-state 2>/dev/null || echo "N/A")
    echo -e "  • Touchpad Wayland:          Tap: ${CYAN}${tap_click}${NC} | Scroll Natural: ${CYAN}${nat_scroll}${NC} | Arrastre: ${CYAN}${tap_drag}${NC}"
    echo -e "  • Teclado NumLock Memoria:   ${CYAN}${numlock}${NC}"

    local mutter_workspaces night_light
    mutter_workspaces=$(run_as_user gsettings get org.gnome.mutter workspaces-only-on-primary 2>/dev/null || echo "N/A")
    if [[ "$mutter_workspaces" == "false" ]]; then
        echo -e "  • Espacios Multi-Monitor:    ${GREEN}Habilitados en todas las pantallas${NC}"
    else
        echo -e "  • Espacios Multi-Monitor:    ${YELLOW}Solo pantalla principal${NC}"
    fi

    night_light=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled 2>/dev/null || echo "N/A")
    echo -e "  • Modo Noche (Night Light):  ${CYAN}${night_light}${NC}"

    if systemctl is-active --quiet bluetooth 2>/dev/null; then
        local bt_details=""
        if grep -qE "^FastConnectable\s*=\s*true" /etc/bluetooth/main.conf 2>/dev/null; then
            bt_details="FastConnectable"
        fi
        if grep -qE "^Experimental\s*=\s*true" /etc/bluetooth/main.conf 2>/dev/null; then
            bt_details="${bt_details:+${bt_details} + }Batería de periféricos"
        fi
        echo -e "  • Servicio Bluetooth:        ${GREEN}Activo${NC} (${CYAN}${bt_details:-Predeterminado}${NC})"
    else
        echo -e "  • Servicio Bluetooth:        ${YELLOW}Inactivo${NC}"
    fi

    echo -e "${BOLD}======================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 5. MÓDULO DE GESTIÓN DE ENERGÍA Y HARDWARE
# ------------------------------------------------------------------------------
setup_power() {
    log_info "Configurando gestión de energía en Fedora 45 Workstation (AMD P-State / TuneD)..."

    # Verificar si se requieren paquetes del sistema de forma idempotente
    local pkgs_to_install=()
    if ! rpm -q tuned-ppd &>/dev/null && ! rpm -q power-profiles-daemon &>/dev/null; then
        pkgs_to_install+=(tuned tuned-ppd)
    fi
    if ! rpm -q switcheroo-control &>/dev/null; then
        pkgs_to_install+=(switcheroo-control)
    fi

    if [[ ${#pkgs_to_install[@]} -gt 0 ]]; then
        log_info "Instalando dependencias de energía: ${pkgs_to_install[*]}..."
        $SUDO "$DNF_BIN" install -y "${pkgs_to_install[@]}"
    fi

    # Resolver conflictos: TLP interfiere con tuned-ppd / power-profiles-daemon y amd-pstate-epp
    if systemctl is-active --quiet tlp 2>/dev/null || systemctl is-enabled --quiet tlp 2>/dev/null; then
        log_warn "Desactivando TLP para permitir que tuned gestione la energía sin colisiones..."
        $SUDO systemctl stop tlp 2>/dev/null || true
        $SUDO systemctl mask tlp 2>/dev/null || true
    fi

    # Habilitar y arrancar servicios si no estuviesen activos
    if ! systemctl is-active --quiet tuned.service 2>/dev/null || ! systemctl is-active --quiet tuned-ppd.service 2>/dev/null; then
        if systemctl list-unit-files | grep -q "^tuned.service"; then
            $SUDO systemctl enable --now tuned.service tuned-ppd.service 2>/dev/null || true
        elif systemctl list-unit-files | grep -q "^power-profiles-daemon.service"; then
            $SUDO systemctl enable --now power-profiles-daemon.service 2>/dev/null || true
        fi
    fi

    if systemctl list-unit-files | grep -q "^switcheroo-control.service" && ! systemctl is-active --quiet switcheroo-control.service 2>/dev/null; then
        $SUDO systemctl enable --now switcheroo-control.service 2>/dev/null || true
    fi

    # Ajustes de energía en GNOME Shell (Operación puramente de usuario vía gsettings)
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend' 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1200 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power idle-dim true 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.session idle-delay 900 2>/dev/null || true

    # Activar ahorro automático en batería baja (si el esquema está presente)
    if run_as_user gsettings list-keys org.gnome.settings-daemon.plugins.power 2>/dev/null | grep -q "^power-saver-profile-on-low-battery$"; then
        run_as_user gsettings set org.gnome.settings-daemon.plugins.power power-saver-profile-on-low-battery true 2>/dev/null || true
    fi

    # Establecer perfil 'balanced' nativamente (TuneD-PPD gestiona automáticamente AC vs Batería)
    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set balanced 2>/dev/null || true
    elif command -v gdbus &>/dev/null; then
        gdbus call --system --dest net.hadess.PowerProfiles --object-path /net/hadess/PowerProfiles \
            --method org.freedesktop.DBus.Properties.Set "net.hadess.PowerProfiles" "ActiveProfile" "<'balanced'>" >/dev/null 2>&1 || true
    elif command -v tuned-adm &>/dev/null; then
        tuned-adm profile balanced-battery 2>/dev/null || tuned-adm profile balanced 2>/dev/null || true
    fi

    log_ok "Gestión de energía y perfiles configurados con éxito."
}

# ------------------------------------------------------------------------------
# 6. MÓDULO DE TOUCHPAD Y TECLADO WAYLAND (100% Rootless)
# ------------------------------------------------------------------------------
setup_touchpad() {
    log_info "Optimizando Touchpad Wayland, gestos multitáctiles y teclado..."
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad click-method 'fingers' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true 2>/dev/null || true

    # Teclado: recordar y mantener activo el bloque numérico del HP ProBook 455 G10
    run_as_user gsettings set org.gnome.desktop.peripherals.keyboard remember-numlock-state true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.keyboard numlock-state true 2>/dev/null || true

    # Si se ejecuta con privilegios de root, asegurar miembros en video e input
    if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
        usermod -aG video,input "$REAL_USER" 2>/dev/null || true
    fi

    log_ok "Touchpad multitáctil Wayland y memoria del teclado numérico configurados."
}

# ------------------------------------------------------------------------------
# 7. MÓDULO DE PANTALLA Y MUTTER WAYLAND (100% Rootless)
# ------------------------------------------------------------------------------
setup_display() {
    log_info "Configurando Mutter Wayland para topología multimonitor (DP-3, DP-4, eDP-1)..."

    # Mutter experimental-features (adaptativo según compatibilidad del esquema en Mutter 48/51+)
    if run_as_user gsettings list-keys org.gnome.mutter 2>/dev/null | grep -q "^experimental-features$"; then
        local range features=()
        range=$(run_as_user gsettings range org.gnome.mutter experimental-features 2>/dev/null || true)
        if echo "$range" | grep -q "scale-monitor-framebuffer"; then
            features+=("'scale-monitor-framebuffer'")
        fi
        if echo "$range" | grep -q "variable-refresh-rate"; then
            features+=("'variable-refresh-rate'")
        fi
        if echo "$range" | grep -q "xwayland-native-scaling"; then
            features+=("'xwayland-native-scaling'")
        fi

        if [[ ${#features[@]} -gt 0 ]]; then
            local features_str="[$(IFS=', '; echo "${features[*]}")]"
            run_as_user gsettings set org.gnome.mutter experimental-features "$features_str" 2>/dev/null || true
            log_info "Características Mutter aplicadas: $features_str"
        fi
    else
        log_info "Mutter Wayland v51+ cuenta con escalado fraccional y sincronización adaptativa nativas."
    fi

    # Comportamiento multimonitor y gestión de ventanas
    run_as_user gsettings set org.gnome.mutter workspaces-only-on-primary false 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter edge-tiling true 2>/dev/null || true

    # Modo noche suave a 4000K para sesiones de programación
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic true 2>/dev/null || true

    log_ok "Mutter Wayland, espacios multimonitor y Luz Nocturna configurados."
}

# ------------------------------------------------------------------------------
# 8. MÓDULO DE CIERRE DE TAPA EN ESTACIÓN ACOPLADA (systemd-logind)
# ------------------------------------------------------------------------------
setup_logind() {
    log_info "Configurando cierre de tapa inteligente en estación acoplada ($LOGIND_DROPIN_FILE)..."
    local content
    content=$(cat << 'EOF'
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
)

    if [[ -f "$LOGIND_DROPIN_FILE" ]] && [[ "$(cat "$LOGIND_DROPIN_FILE" 2>/dev/null)" == "$content" ]]; then
        log_info "La configuración de tapa en systemd-logind ya está al día."
    else
        $SUDO mkdir -p "$LOGIND_DROPIN_DIR"
        echo "$content" | $SUDO tee "$LOGIND_DROPIN_FILE" > /dev/null
        # IMPORTANTE: NUNCA usar 'systemctl restart systemd-logind' dentro de una sesión gráfica activa
        $SUDO systemctl reload systemd-logind 2>/dev/null || $SUDO kill -HUP "$(pidof systemd-logind 2>/dev/null)" 2>/dev/null || true
    fi

    log_ok "systemd-logind configurado y recargado de forma segura sin interrumpir la sesión Wayland."
}

# ------------------------------------------------------------------------------
# 9. MÓDULO DE BLUETOOTH (FastConnectable y Batería de Periféricos)
# ------------------------------------------------------------------------------
setup_bluetooth() {
    log_info "Optimizando pila Bluetooth BlueZ (AutoEnable, FastConnectable y Batería)..."
    local bt_conf="/etc/bluetooth/main.conf"
    local needs_restart=false

    if [[ -f "$bt_conf" ]]; then
        # FastConnectable
        if ! grep -qE "^FastConnectable\s*=\s*true" "$bt_conf" 2>/dev/null; then
            if grep -q "^#*FastConnectable" "$bt_conf" 2>/dev/null; then
                $SUDO sed -i 's/^#*FastConnectable.*/FastConnectable = true/' "$bt_conf"
            else
                echo "FastConnectable = true" | $SUDO tee -a "$bt_conf" > /dev/null
            fi
            needs_restart=true
        fi

        # Experimental: expone el nivel de batería de periféricos (ratón, auriculares) en GNOME Shell
        if ! grep -qE "^Experimental\s*=\s*true" "$bt_conf" 2>/dev/null; then
            if grep -q "^#*Experimental\s*=" "$bt_conf" 2>/dev/null; then
                $SUDO sed -i 's/^#*Experimental\s*=.*/Experimental = true/' "$bt_conf"
            else
                echo "Experimental = true" | $SUDO tee -a "$bt_conf" > /dev/null
            fi
            needs_restart=true
        fi

        # AutoEnable
        if ! grep -qE "^AutoEnable\s*=\s*true" "$bt_conf" 2>/dev/null; then
            if grep -q "^#*AutoEnable" "$bt_conf" 2>/dev/null; then
                $SUDO sed -i 's/^#*AutoEnable.*/AutoEnable = true/' "$bt_conf"
            else
                echo "AutoEnable = true" | $SUDO tee -a "$bt_conf" > /dev/null
            fi
            needs_restart=true
        fi
    else
        $SUDO mkdir -p /etc/bluetooth
        cat << 'EOF' | $SUDO tee "$bt_conf" > /dev/null
[General]
AutoEnable = true
FastConnectable = true
Experimental = true
EOF
        needs_restart=true
    fi

    if [[ "$needs_restart" == true ]] || ! systemctl is-active --quiet bluetooth.service 2>/dev/null; then
        $SUDO systemctl enable --now bluetooth.service 2>/dev/null || true
        $SUDO systemctl restart bluetooth.service 2>/dev/null || true
    fi

    log_ok "Bluetooth configurado y activo (AutoEnable, FastConnectable y nivel de batería de periféricos)."
}

# ------------------------------------------------------------------------------
# 10. ENTRADA PRINCIPAL Y GESTIÓN DE PARÁMETROS
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status|status)
            ACTION="status"
            shift
            ;;
        -p|--power)
            RUN_ALL=false
            RUN_POWER=true
            shift
            ;;
        -t|--touchpad)
            RUN_ALL=false
            RUN_TOUCHPAD=true
            shift
            ;;
        -d|--display)
            RUN_ALL=false
            RUN_DISPLAY=true
            shift
            ;;
        -l|--logind)
            RUN_ALL=false
            RUN_LOGIND=true
            shift
            ;;
        -b|--bluetooth)
            RUN_ALL=false
            RUN_BLUETOOTH=true
            shift
            ;;
        -h|--help|help)
            show_help
            exit 0
            ;;
        *)
            log_err "Opción desconocida: $1"
            show_help
            exit 1
            ;;
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
    echo ""
    log_ok "Optimización completa de portátil para Fedora 45 Workstation finalizada con éxito."
    echo ""
    show_status
else
    [[ "$RUN_POWER" == true ]]     && setup_power
    [[ "$RUN_TOUCHPAD" == true ]]  && setup_touchpad
    [[ "$RUN_DISPLAY" == true ]]   && setup_display
    [[ "$RUN_LOGIND" == true ]]    && setup_logind
    [[ "$RUN_BLUETOOTH" == true ]] && setup_bluetooth
    echo ""
    log_ok "Módulos seleccionados configurados con éxito."
fi
